function S = generateNetworkState(net,P,round)
%GENERATENETWORKSTATE Build the 9-dimensional dynamic network state.
% State order follows the new abstract:
% [residualEnergy, distance, delay, degree, signalStrength,
%  mobility, trafficLoad, trustValue, throughput]

N = P.N;
S = zeros(N,9);
alive = net.energy > P.energyDeathThreshold;

Dbs = pdist2(net.pos,P.BS);
[minD,~] = min(Dbs,[],2);

D = pdist2(net.pos,net.pos);
degree = sum(D <= 25,2)-1;
degree(~alive)=0;

if round == 1
    mobility = zeros(N,1);
else
    mobility = vecnorm(net.pos-net.prevPos,2,2);
end
mobility = min(mobility/max(P.maxMobility,eps),1);

traffic = 0.20 + 0.55*rand(N,1);
traffic = min(traffic + 0.20*(1-net.energy/P.initialEnergy),1);

signal = exp(-minD/(0.45*sqrt(P.areaX^2+P.areaY^2)));
signal = max(0,min(signal,1));

delay = min(0.05 + 0.45*traffic + 0.25*(1-signal) + ...
            0.15*mobility + 0.05*rand(N,1),1);

throughput = signal .* (1-0.55*traffic) .* ...
             max(net.energy/P.initialEnergy,0) .* (1-0.25*delay);
throughput = max(0,min(throughput,1));

S(:,1) = max(net.energy,0);
S(:,2) = minD;
S(:,3) = delay;
S(:,4) = degree;
S(:,5) = signal;
S(:,6) = mobility;
S(:,7) = traffic;
S(:,8) = net.trust;
S(:,9) = throughput;
S(~alive,:) = 0;
end
