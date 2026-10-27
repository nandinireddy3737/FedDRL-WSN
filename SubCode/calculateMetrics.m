function M=calculateMetrics(net,clusters,routes,CHs,txInfo,chInfo,routeInfo,P)
%CALCULATEMETRICS New-abstract WSN evaluation metrics.

alive=sum(net.energy>P.energyDeathThreshold);
M.aliveNodes=alive;
M.deadNodes=P.N-alive;
M.energyConsumedRound=txInfo.energyConsumed;
M.totalEnergyConsumed=txInfo.cumulativeEnergyConsumed;
M.residualEnergy=sum(net.energy);
M.endToEndDelay=txInfo.delay;

if txInfo.generatedPackets>0
    M.PDR=min(1,txInfo.deliveredPackets/txInfo.generatedPackets);
else
    M.PDR=0;
end
M.packetLoss=1-M.PDR;
M.throughput=txInfo.deliveredPackets*P.packetBits/1000; % kb/round
M.routingOverhead=txInfo.controlPackets/max(txInfo.generatedPackets,1);

% Routing reliability combines delivery and learned route quality.
if routeInfo.numRoutes>0
    M.routingReliability=max(0,min(1,0.70*M.PDR+0.30*routeInfo.meanScore));
else
    M.routingReliability=0;
end

loads=zeros(numel(clusters),1);
for k=1:numel(clusters)
    loads(k)=max(numel(clusters{k})-1,0);
end
if ~isempty(loads) && mean(loads)>0
    cv=std(loads)/(mean(loads)+eps);
    M.loadBalance=1/(1+cv);
else
    M.loadBalance=0;
end

if isempty(CHs)
    M.clusterStability=0;
else
    energyStability=mean(net.energy(CHs)/P.initialEnergy);
    mobilityPenalty=mean(min(net.mobility(CHs)/max(P.maxMobility,eps),1));
    M.clusterStability=max(0,min(1,energyStability*(1-mobilityPenalty)));
end

M.chEfficiency=chInfo.bestFitness;
end
