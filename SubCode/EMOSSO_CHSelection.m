function [CHs,info] = EMOSSO_CHSelection(net,S,A,policy,P)
%EMOSSO_CHSELECTION E-MOSSO multi-objective cluster-head selection.

alive=find(net.energy>P.energyDeathThreshold);
if numel(alive)<=P.minCH
    CHs=alive(:)';
    info.bestFitness=0;
    info.population=[];
    info.target=numel(CHs);
    return;
end

% Dynamic target around the desired CH ratio.
energyMean=mean(net.energy(alive))/P.initialEnergy;
trafficMean=mean(S(alive,7));
healthFactor=0.6*energyMean+0.4*(1-trafficMean);
target=round(P.numCHTarget*(0.85+0.30*healthFactor));
target=max(P.minCH,min([P.maxCH,target,numel(alive)]));

pop=initializeMOSSO(P.mossoPopulation,numel(alive),target);
best=pop(1,:);
bestFit=-inf;
history=zeros(P.mossoIterations,1);

for it=1:P.mossoIterations
    c1=2*exp(-(4*it/P.mossoIterations)^2);
    fitness=zeros(size(pop,1),1);

    for s=1:size(pop,1)
        selected=alive(logical(pop(s,:)));
        fitness(s)=CHFitness(selected,net,S,A,policy,P);
    end

    [mx,ix]=max(fitness);
    if mx>bestFit
        bestFit=mx;
        best=pop(ix,:);
    end
    history(it)=bestFit;

    leader=double(best);
    leaderNoise=c1*randn(size(leader));
    pop(1,:)=leader+leaderNoise > 0.5;

    for s=2:size(pop,1)
        prob=0.5*(double(pop(s,:))+double(pop(s-1,:)));
        pop(s,:)=rand(size(prob))<prob;
    end

    % Enhanced diversification that decays over iterations.
    mutationRate=0.10*(1-it/P.mossoIterations)+0.01;
    pop=xor(pop,rand(size(pop))<mutationRate);

    for s=1:size(pop,1)
        pop(s,:)=repairCH(pop(s,:),target);
    end
end

CHs=alive(logical(best));
if isempty(CHs)
    [~,ix]=max(net.energy(alive));
    CHs=alive(ix);
end

info.bestFitness=bestFit;
info.population=pop;
info.target=target;
info.history=history;
end

function b=repairCH(b,target)
b=logical(b);
idx=find(b);
if numel(idx)>target
    keep=idx(randperm(numel(idx),target));
    b(:)=false;
    b(keep)=true;
elseif numel(idx)<target
    z=find(~b);
    nAdd=min(target-numel(idx),numel(z));
    if nAdd>0
        add=z(randperm(numel(z),nAdd));
        b(add)=true;
    end
end
end
