clear; clc; close all;
addpath(genpath('.\SubCode\'))
rng(42,'twister');

P=defaultParameters();

fprintf('Initializing %d-node WSN with %d base stations...\n',P.N,P.numBS);
net=initializeWSN(P);
normP=stateNormalizationParameters(P);
agents=initializeFedDRL(P,normP);
drift=initializeADWIN(P);
R=initializeResults(P);

fprintf('Starting updated simulation for %d rounds...\n',P.rounds);

for round=1:P.rounds
    alive=find(net.energy>P.energyDeathThreshold);
    if numel(alive)<P.minAliveNodes
        R.actualRounds=round-1;
        fprintf('Network stopped at round %d.\n',round);
        break;
    end

    % 1. Dynamic 9-feature state
    rawState=generateNetworkState(net,P,round);

    % 2. PMAM attention
    [attentionState,pmamInfo]=PMAM_Attention(rawState,normP,P); 

    % 3. Periodic E-MOSSO hyperparameter optimization
    if P.hyperOptEnabled && (round==1 || mod(round-1,P.hyperOptEvery)==0)
        [P,hyperInfo]=EMOSSO_HyperparameterOptimization(P,rawState,agents,round); 
    end

    % 4. Federated local A-AC-PPO + DRND
    clientData=makeFederatedClientData(attentionState,net,P);
    [agents,localReward,localLoss]=localAACPPO(agents,clientData,net,P,round);

    % 5. ADWIN drift detection
    % Use a composite state/reward signal to improve sensitivity to network change.
    driftSignal=0.50*mean(localReward)+ ...
                0.20*mean(rawState(alive,1))/P.initialEnergy + ...
                0.15*mean(rawState(alive,9)) + ...
                0.15*(1-mean(rawState(alive,7)));
    [drift,driftDetected]=ADWIN_DriftDetection(drift,driftSignal,P);

    if driftDetected
        agents=adaptAfterDrift(agents,P);
        fprintf('Round %4d: ADWIN drift -> local adaptation + adaptive FedAvg\n',round);
    end

    % 6. Federated aggregation
    agents=federatedAggregation(agents,P,driftDetected);
    policy=getGlobalPolicy(agents);

    % 7. E-MOSSO CH selection
    [CHs,chInfo]=EMOSSO_CHSelection(net,rawState,attentionState,policy,P);

    % 8. Cluster formation
    clusters=formClusters(net,CHs,P);

    % 9. A-AC-PPO next-hop routing
    [routes,routingInfo]=AACPPO_Routing(net,clusters,CHs,rawState,policy,P);

    % 10. Transmission + energy update
    [net,txInfo]=updateEnergy(net,clusters,routes,CHs,P);

    % 11. Metrics
    metrics=calculateMetrics(net,clusters,routes,CHs,txInfo,chInfo,routingInfo,P);

    R.energyRound(round)=metrics.energyConsumedRound;
    R.energy(round)=metrics.totalEnergyConsumed;
    R.residualEnergy(round)=metrics.residualEnergy;
    R.alive(round)=metrics.aliveNodes;
    R.dead(round)=metrics.deadNodes;
    R.delay(round)=metrics.endToEndDelay;
    R.throughput(round)=metrics.throughput;
    R.reliability(round)=metrics.routingReliability;
    R.loadBalance(round)=metrics.loadBalance;
    R.PDR(round)=metrics.PDR;
    R.packetLoss(round)=metrics.packetLoss;
    R.routingOverhead(round)=metrics.routingOverhead;
    R.stability(round)=metrics.clusterStability;
    R.reward(round)=mean(localReward);
    R.loss(round)=mean(localLoss);
    R.drift(round)=driftDetected;
    R.numCH(round)=numel(CHs);
    R.actorLR(round)=P.actorLearningRate;
    R.criticLR(round)=P.criticLearningRate;
    R.ppoClip(round)=P.ppoClip;
    R.intrinsicWeight(round)=P.intrinsicWeight;
    R.actualRounds=round;

    % FND/HND/LND
    if isnan(R.FND) && metrics.aliveNodes<P.N, R.FND=round; end
    if isnan(R.HND) && metrics.aliveNodes<=P.N/2, R.HND=round; end
    if isnan(R.LND) && metrics.aliveNodes==0, R.LND=round; end

    if mod(round,P.displayEvery)==0 || round==1
        fprintf(['Round %4d | Alive %3d | CH %2d | PDR %.3f | ', ...
                 'Thr %.1f kb/r | Cum.E %.3f J | Delay %.5f\n'], ...
            round,metrics.aliveNodes,numel(CHs),metrics.PDR, ...
            metrics.throughput,metrics.totalEnergyConsumed,metrics.endToEndDelay);
    end
end

% Trim time-series arrays only.
nR=R.actualRounds;
fields=fieldnames(R);
for i=1:numel(fields)
    v=R.(fields{i});
    if isnumeric(v) && isvector(v) && numel(v)==P.rounds
        R.(fields{i})=v(1:nR);
    end
end

plotResults(R,net,P);
save(fullfile('FedDRL_DA_MOO_NewAbstract_results.mat'), ...
    'R','net','P','agents');
T=resultsTable(R);
writetable(T,fullfile('FedDRL_DA_MOO_NewAbstract_results.csv'));

fprintf('\nUpdated simulation completed.\n');
fprintf('FND = %g, HND = %g, LND = %g\n',R.FND,R.HND,R.LND);
fprintf('Results saved');
