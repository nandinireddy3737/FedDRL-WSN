function score=CHFitness(CH,net,S,A,policy,P)
%CHFITNESS Multi-objective E-MOSSO CH fitness for the new abstract.
% Objectives: residual energy, communication distance, node degree,
% signal strength, traffic load, trust value and throughput.

if isempty(CH)
    score=-1e9;
    return;
end

alive=find(net.energy>P.energyDeathThreshold);
if isempty(alive)
    score=-1e9;
    return;
end

e=mean(net.energy(CH))/P.initialEnergy;

D=pdist2(net.pos(CH,:),net.pos(alive,:));
nearest=min(D,[],1);
distanceScore=1-min(mean(nearest)/sqrt(P.areaX^2+P.areaY^2),1);

degree=mean(S(CH,4))/max(P.N-1,1);
signal=mean(S(CH,5));
traffic=1-mean(S(CH,7));
trust=mean(S(CH,8));
throughput=mean(S(CH,9));

obj=[e distanceScore degree signal traffic trust throughput];

% Policy-aware mild adaptation of the fixed multi-objective weights.
w=P.chWeights;
w=w.*[1+0.25*policy.energy, ...
      1+0.25*policy.distance, ...
      1, ...
      1+0.25*policy.signal, ...
      1+0.25*policy.traffic, ...
      1+0.25*policy.trust, ...
      1];
w=w/(sum(w)+eps);

% PMAM contribution: favor candidates whose attended states are informative.
attentionScore=mean(A(CH,:),'all');
score=sum(w.*obj)+0.03*attentionScore;

penalty=0.03*abs(numel(CH)-P.numCHTarget)/max(P.N,1);
score=score-penalty;
end
