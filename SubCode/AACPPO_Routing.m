function [routes,info] = AACPPO_Routing(net,clusters,CHs,S,policy,P)
%AACPPO_ROUTING Next-hop routing driven by the global A-AC-PPO policy.
%
% E-MOSSO is intentionally NOT used here. For each CH, the actor-derived
% routing preferences score feasible CH and BS next hops. To avoid loops,
% CH relays are restricted to nodes that are closer to a BS than the source.

nCH=numel(CHs);
routes=struct('source',{},'destination',{},'type',{},'score',{});

if nCH==0
    info.numRoutes=0;
    info.meanScore=0;
    info.bsReachableFraction=0;
    return;
end

Dch=pdist2(net.pos(CHs,:),net.pos(CHs,:));
Dbs=pdist2(net.pos(CHs,:),P.BS);
[minSrcBS,~]=min(Dbs,[],2);

for i=1:nCH
    src=CHs(i);
    candidateScores=[];
    candidateType={};
    candidateDest={};

    % Direct BS candidates
    for b=1:P.numBS
        d=Dbs(i,b);
        if d<=1.5*P.maxCommunicationDistance || b==find(Dbs(i,:)==min(Dbs(i,:)),1)
            sig=exp(-d/50);
            e=net.energy(src)/P.initialEnergy;
            trust=S(src,8);
            traffic=1-S(src,7);
            distScore=1-min(d/sqrt(P.areaX^2+P.areaY^2),1);
            score=routeScore(e,distScore,sig,trust,traffic,policy,P);
            candidateScores(end+1)=score; %#ok<AGROW>
            candidateType{end+1}='CH-BS'; %#ok<AGROW>
            candidateDest{end+1}=P.BS(b,:); %#ok<AGROW>
        end
    end

    % Relay CH candidates: must be closer to a BS than source.
    for j=1:nCH
        if j==i, continue; end
        if Dch(i,j)>P.maxCommunicationDistance, continue; end
        if minSrcBS(j)>=minSrcBS(i), continue; end

        dst=CHs(j);
        d=Dch(i,j);
        sig=exp(-d/50)*S(dst,5);
        e=net.energy(dst)/P.initialEnergy;
        trust=mean([S(src,8) S(dst,8)]);
        traffic=1-S(dst,7);
        distScore=1-min(d/sqrt(P.areaX^2+P.areaY^2),1);
        score=routeScore(e,distScore,sig,trust,traffic,policy,P);

        candidateScores(end+1)=score; %#ok<AGROW>
        candidateType{end+1}='CH-CH'; %#ok<AGROW>
        candidateDest{end+1}=dst; %#ok<AGROW>
    end

    [bestScore,k]=max(candidateScores);
    routes(end+1)=struct('source',src, ... %#ok<AGROW>
        'destination',candidateDest{k}, ...
        'type',candidateType{k}, ...
        'score',bestScore);
end

info.numRoutes=numel(routes);
info.meanScore=mean([routes.score]);
info.bsReachableFraction=mean(strcmp({routes.type},'CH-BS'));
end

function score=routeScore(e,d,sig,trust,traffic,policy,P)
% Normalize base weights and adapt them using global policy components.
w=[P.routeEnergyWeight P.routeDistanceWeight P.routeSignalWeight ...
   P.routeTrustWeight P.routeTrafficWeight];
w=w.*[1+policy.energy 1+policy.distance 1+policy.signal ...
      1+policy.trust 1+policy.traffic];
w=w/(sum(w)+eps);
score=sum(w.*[e d sig trust traffic]);
end
