function [net,info] = updateEnergy(net,clusters,routes,CHs,P)
%UPDATEENERGY
% Updated energy + communication model for the new abstract.
%
% Supports:
% 1. Member -> CH communication
% 2. Dynamic wireless link success probability
% 3. CH aggregation energy
% 4. A-AC-PPO selected CH -> CH / BS routing
% 5. Interference, mobility and trust effects
% 6. Idle + sensing energy consumption
% 7. Realistic packet loss, PDR and throughput
% 8. Node energy depletion / death
%
% NOTE:
% PDR is based only on application packets that successfully reach a BS.

%% =========================================================
% INITIAL VALUES
% =========================================================

before = net.energy;

generatedPackets = 0;
deliveredPackets = 0;
failedPackets = 0;

totalDelay = 0;

controlPackets = 0;

% Number of application packets collected by each CH
payload = zeros(numel(CHs),1);


%% =========================================================
% SAFETY PARAMETERS
% =========================================================
% These defaults are used if the parameters have not yet
% been added to defaultParameters.m

if ~isfield(P,'Eidle')
    P.Eidle = 5e-6;       % J/node/round
end

if ~isfield(P,'Esense')
    P.Esense = 8e-6;      % J/node/round
end

if ~isfield(P,'initialEnergy')
    P.initialEnergy = max(net.initialEnergy);
end


%% =========================================================
% 1. MEMBER -> CH DATA COLLECTION
% =========================================================

for c = 1:numel(clusters)

    members = clusters{c};

    ch = CHs(c);

    %% Skip dead CH
    if net.energy(ch) <= P.energyDeathThreshold
        continue;
    end

    %% -----------------------------------------------------
    % CH generates its own sensing packet
    %% -----------------------------------------------------

    generatedPackets = generatedPackets + 1;

    payload(c) = payload(c) + 1;


    %% -----------------------------------------------------
    % Member nodes send packets to their CH
    %% -----------------------------------------------------

    for m = members

        %% Ignore CH itself
        if m == ch
            continue;
        end

        %% Ignore dead node
        if net.energy(m) <= P.energyDeathThreshold
            continue;
        end

        generatedPackets = generatedPackets + 1;

        %% Distance member -> CH
        d = norm(net.pos(m,:) - net.pos(ch,:));

        %% Transmission / reception energy
        Etx = transmissionEnergy(P.packetBits,d,P);

        Erx = P.packetBits * P.Eelec;


        %% =================================================
        % DYNAMIC MEMBER -> CH LINK QUALITY
        %% =================================================

        % Distance quality
        distanceFactor = exp(-d/80);

        % Residual-energy quality
        energyFactor = min(1, ...
            net.energy(m)/(P.initialEnergy + eps));

        % Mobility quality
        mobilityFactor = exp( ...
            -0.35*net.mobility(m));

        % Node trust
        trustFactor = net.trust(m);

        % Random wireless interference
        interferenceFactor = ...
            0.85 + 0.15*rand;


        %% Overall link success probability

        linkProb = ...
            0.30*distanceFactor + ...
            0.20*energyFactor + ...
            0.15*mobilityFactor + ...
            0.20*trustFactor + ...
            0.15*interferenceFactor;


        %% Bound probability

        linkProb = max( ...
            0.70, ...
            min(0.995,linkProb));


        %% Random link outcome

        linkSuccess = rand < linkProb;


        %% =================================================
        % SUCCESSFUL MEMBER -> CH TRANSMISSION
        %% =================================================

        if net.energy(m) > Etx && ...
           net.energy(ch) > Erx && ...
           linkSuccess

            %% Energy update

            net.energy(m) = ...
                net.energy(m) - Etx;

            net.energy(ch) = ...
                net.energy(ch) - Erx;


            %% Communication counters

            net.totalSent(m) = ...
                net.totalSent(m) + 1;

            net.totalReceived(ch) = ...
                net.totalReceived(ch) + 1;

            net.successfulLinks(m) = ...
                net.successfulLinks(m) + 1;


            %% Packet successfully reaches CH

            payload(c) = ...
                payload(c) + 1;


            %% Delay
            % Seconds

            propagationDelay = d/10000;

            queueDelay = ...
                0.001 + 0.003*rand;

            totalDelay = ...
                totalDelay + ...
                0.003 + ...
                propagationDelay + ...
                queueDelay;


        else

            %% Failed packet

            failedPackets = ...
                failedPackets + 1;

            net.failedLinks(m) = ...
                net.failedLinks(m) + 1;

        end

    end

end


%% =========================================================
% 2. CREATE ROUTING MAP
% =========================================================

routeMap = ...
    containers.Map( ...
    'KeyType','double', ...
    'ValueType','double');


for i = 1:numel(routes)

    routeMap(routes(i).source) = i;

end


%% =========================================================
% 3. CH AGGREGATION + ROUTING TO BS
% =========================================================

for c = 1:numel(CHs)

    %% Nothing collected
    if payload(c) <= 0
        continue;
    end

    current = CHs(c);

    packetCount = payload(c);

    visited = [];

    success = true;

    hop = 0;


    %% =====================================================
    % AGGREGATION ENERGY
    %% =====================================================

    aggregationEnergy = ...
        packetCount * ...
        P.packetBits * ...
        P.EDA;


    if net.energy(current) > aggregationEnergy

        net.energy(current) = ...
            net.energy(current) - ...
            aggregationEnergy;

    else

        failedPackets = ...
            failedPackets + packetCount;

        continue;

    end


    %% =====================================================
    % ROUTING LOOP
    %% =====================================================

    while true

        hop = hop + 1;


        %% Avoid routing loops

        if hop > numel(CHs)+1 || ...
           ismember(current,visited) || ...
           ~isKey(routeMap,current)

            success = false;

            break;

        end


        visited(end+1) = current; %#ok<AGROW>


        %% Routing decision obtained from A-AC-PPO

        r = routes(routeMap(current));


        %% Count routing control message

        controlPackets = ...
            controlPackets + 1;


        %% =================================================
        % CASE A: CH -> BASE STATION
        %% =================================================

        if strcmp(r.type,'CH-BS')

            %% Distance to BS

            d = norm( ...
                net.pos(current,:) - ...
                r.destination);


            %% Transmission energy

            Etx = ...
                transmissionEnergy( ...
                P.packetBits,d,P);


            %% =============================================
            % CH -> BS LINK SUCCESS PROBABILITY
            %% =============================================

            signalProb = ...
                exp(-d/120);


            energyProb = ...
                min(1, ...
                net.energy(current)/ ...
                (P.initialEnergy + eps));


            trustProb = ...
                net.trust(current);


            interferenceProb = ...
                0.88 + ...
                0.12*rand;


            routeSuccessProb = ...
                0.35*signalProb + ...
                0.25*energyProb + ...
                0.20*trustProb + ...
                0.20*interferenceProb;


            routeSuccessProb = ...
                max(0.72, ...
                min(0.995, ...
                routeSuccessProb));


            routeSuccess = ...
                rand < routeSuccessProb;


            %% Successful CH -> BS

            if net.energy(current) > Etx && ...
               routeSuccess


                net.energy(current) = ...
                    net.energy(current) - Etx;


                net.successfulLinks(current) = ...
                    net.successfulLinks(current) + 1;


                net.totalSent(current) = ...
                    net.totalSent(current) + 1;


                %% Delay in seconds

                propagationDelay = ...
                    d/10000;

                queueDelay = ...
                    0.002 + ...
                    0.004*rand;

                totalDelay = ...
                    totalDelay + ...
                    0.006 + ...
                    propagationDelay + ...
                    queueDelay;


                %% Payload reached BS

                break;


            else

                success = false;

                net.failedLinks(current) = ...
                    net.failedLinks(current) + 1;

                break;

            end


        %% =================================================
        % CASE B: CH -> CH
        %% =================================================

        else

            next = r.destination;


            %% Validate next node

            if next < 1 || ...
               next > P.N || ...
               net.energy(next) <= ...
               P.energyDeathThreshold

                success = false;

                break;

            end


            %% Distance

            d = norm( ...
                net.pos(current,:) - ...
                net.pos(next,:));


            %% TX/RX energy

            Etx = ...
                transmissionEnergy( ...
                P.packetBits,d,P);

            Erx = ...
                P.packetBits * ...
                P.Eelec;


            %% =============================================
            % CH -> CH LINK QUALITY
            %% =============================================

            signalProb = ...
                exp(-d/90);


            trustProb = ...
                0.5 * ...
                (net.trust(current) + ...
                 net.trust(next));


            mobilityProb = ...
                exp( ...
                -0.30*net.mobility(next));


            energyProb = ...
                min(1, ...
                net.energy(next)/ ...
                (P.initialEnergy + eps));


            interferenceProb = ...
                0.85 + ...
                0.15*rand;


            routeSuccessProb = ...
                0.30*signalProb + ...
                0.20*trustProb + ...
                0.15*mobilityProb + ...
                0.15*energyProb + ...
                0.20*interferenceProb;


            routeSuccessProb = ...
                max(0.70, ...
                min(0.995, ...
                routeSuccessProb));


            routeSuccess = ...
                rand < routeSuccessProb;


            %% =============================================
            % Successful CH -> CH communication
            %% =============================================

            if net.energy(current) > Etx && ...
               net.energy(next) > Erx && ...
               routeSuccess


                net.energy(current) = ...
                    net.energy(current) - Etx;


                net.energy(next) = ...
                    net.energy(next) - Erx;


                net.successfulLinks(current) = ...
                    net.successfulLinks(current) + 1;


                net.totalSent(current) = ...
                    net.totalSent(current) + 1;


                net.totalReceived(next) = ...
                    net.totalReceived(next) + 1;


                %% Delay

                propagationDelay = ...
                    d/10000;

                queueDelay = ...
                    0.002 + ...
                    0.004*rand;


                totalDelay = ...
                    totalDelay + ...
                    0.006 + ...
                    propagationDelay + ...
                    queueDelay;


                %% Move to next CH

                current = next;


            else

                success = false;


                net.failedLinks(current) = ...
                    net.failedLinks(current) + 1;


                break;

            end

        end

    end


    %% =====================================================
    % COUNT DELIVERED APPLICATION PACKETS
    %% =====================================================

    if success

        deliveredPackets = ...
            deliveredPackets + ...
            packetCount;

    else

        failedPackets = ...
            failedPackets + ...
            packetCount;

    end

end


%% =========================================================
% 4. IDLE + SENSING ENERGY
% =========================================================

aliveIdx = find( ...
    net.energy > ...
    P.energyDeathThreshold);


baselineEnergy = ...
    P.Eidle + ...
    P.Esense;


net.energy(aliveIdx) = ...
    net.energy(aliveIdx) - ...
    baselineEnergy;


%% =========================================================
% 5. PREVENT NEGATIVE ENERGY
% =========================================================

net.energy = ...
    max(net.energy,0);


%% =========================================================
% 6. UPDATE TRUST VALUES
% =========================================================

for i = 1:P.N

    attempts = ...
        net.totalSent(i) + ...
        net.failedLinks(i);


    if attempts > 0

        successRatio = ...
            net.totalSent(i) / ...
            (attempts + eps);


        net.trust(i) = ...
            0.90*net.trust(i) + ...
            0.10*successRatio;

    end

end


net.trust = ...
    max(P.minTrust, ...
    min(1,net.trust));


%% =========================================================
% 7. DYNAMIC MOBILITY
% =========================================================

net.prevPos = net.pos;


move = ...
    P.maxMobility/3 * ...
    randn(P.N,2);


%% Dead nodes should not move

deadMask = ...
    net.energy <= ...
    P.energyDeathThreshold;

move(deadMask,:) = 0;


%% Update positions

net.pos = ...
    net.pos + move;


%% Keep nodes inside network area

net.pos(:,1) = ...
    max(0, ...
    min(P.areaX, ...
    net.pos(:,1)));


net.pos(:,2) = ...
    max(0, ...
    min(P.areaY, ...
    net.pos(:,2)));


%% Mobility magnitude

net.mobility = ...
    vecnorm(move,2,2);


%% Update network round

net.round = ...
    net.round + 1;


%% =========================================================
% 8. OUTPUT INFORMATION
% =========================================================

info.energyBefore = ...
    before;

info.energyAfter = ...
    net.energy;


%% Energy consumed in current round

info.energyConsumed = ...
    sum(before - net.energy);


%% Cumulative energy consumption

info.cumulativeEnergyConsumed = ...
    sum(net.initialEnergy - ...
    net.energy);


%% Packet statistics

info.generatedPackets = ...
    generatedPackets;


%% Never allow delivered > generated

info.deliveredPackets = ...
    min(deliveredPackets, ...
    generatedPackets);


info.failed = ...
    max(failedPackets, ...
    generatedPackets - ...
    info.deliveredPackets);


info.controlPackets = ...
    controlPackets;


%% =========================================================
% 9. DELAY
% =========================================================
% Delay is currently returned in SECONDS.
% calculateMetrics.m can convert it to milliseconds.

info.delay = ...
    totalDelay / ...
    max(info.deliveredPackets,1);


%% =========================================================
% 10. ADDITIONAL USEFUL OUTPUTS
% =========================================================

info.packetLoss = ...
    max(0, ...
    generatedPackets - ...
    info.deliveredPackets);


info.PDR = ...
    info.deliveredPackets / ...
    max(generatedPackets,1);


info.aliveNodes = ...
    sum(net.energy > ...
    P.energyDeathThreshold);


info.deadNodes = ...
    P.N - ...
    info.aliveNodes;

end


%% =========================================================
% LOCAL FUNCTION: RADIO ENERGY MODEL
% =========================================================

function E = transmissionEnergy(k,d,P)

if d < P.d0

    %% Free-space model

    E = ...
        k*P.Eelec + ...
        k*P.Efs*d^2;

else

    %% Multipath model

    E = ...
        k*P.Eelec + ...
        k*P.Emp*d^4;

end

end