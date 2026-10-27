function [P,info] = EMOSSO_HyperparameterOptimization(P,S,agents,round)
%EMOSSO_HYPERPARAMETEROPTIMIZATION Tune key FedDRL hyperparameters.
%
% The new abstract states that E-MOSSO optimizes key FedDRL
% hyperparameters, but does not prescribe their exact set. This prototype
% tunes actor LR, critic LR, PPO clip and DRND intrinsic-reward weight.

lb=[P.actorLRBounds(1) P.criticLRBounds(1) ...
    P.ppoClipBounds(1) P.intrinsicBounds(1)];
ub=[P.actorLRBounds(2) P.criticLRBounds(2) ...
    P.ppoClipBounds(2) P.intrinsicBounds(2)];
D=numel(lb);

pop=lb+rand(P.hyperPop,D).*(ub-lb);
best=pop(1,:);
bestFit=inf;
history=zeros(P.hyperIterations,1);

stateHealth=mean(S(:,1)/(P.initialEnergy+eps));
stateTraffic=mean(S(:,7));
stateTrust=mean(S(:,8));
stateThroughput=mean(S(:,9));
currentLoss=mean([agents.loss]);
if ~isfinite(currentLoss), currentLoss=1; end

for it=1:P.hyperIterations
    c1=2*exp(-(4*it/P.hyperIterations)^2);
    fit=zeros(P.hyperPop,1);

    for k=1:P.hyperPop
        x=pop(k,:);
        % Proxy objective: prefer stable, moderate updates while adapting
        % more aggressively when traffic is high or state health is poor.
        targetActor=0.012+0.012*(1-stateHealth)+0.006*stateTraffic;
        targetCritic=0.018+0.012*(1-stateHealth)+0.006*stateTraffic;
        targetClip=0.16+0.06*stateTraffic;
        targetIntrinsic=0.03+0.05*(1-stateThroughput)+0.02*(1-stateTrust);

        normalized=[abs(x(1)-targetActor)/(ub(1)-lb(1)+eps), ...
                    abs(x(2)-targetCritic)/(ub(2)-lb(2)+eps), ...
                    abs(x(3)-targetClip)/(ub(3)-lb(3)+eps), ...
                    abs(x(4)-targetIntrinsic)/(ub(4)-lb(4)+eps)];
        fit(k)=mean(normalized)+0.03*min(currentLoss,5);
    end

    [mn,ix]=min(fit);
    if mn<bestFit
        bestFit=mn;
        best=pop(ix,:);
    end
    history(it)=bestFit;

    % Continuous enhanced salp update.
    pop(1,:)=best + c1*(2*rand(1,D)-1).*(ub-lb)*0.20;
    for k=2:P.hyperPop
        pop(k,:)=0.5*(pop(k,:)+pop(k-1,:));
        pop(k,:)=pop(k,:)+0.03*(1-it/P.hyperIterations)*randn(1,D).*(ub-lb);
    end
    pop=max(lb,min(ub,pop));
end

P.actorLearningRate=best(1);
P.criticLearningRate=best(2);
P.ppoClip=best(3);
P.intrinsicWeight=best(4);

info.bestFitness=bestFit;
info.best=best;
info.history=history;
info.round=round;
end
