function [attended,info] = PMAM_Attention(S,normP,P)
%PMAM_ATTENTION Practical Parallel Mixed Attention Mechanism prototype.
%
% The new abstract specifies PMAM conceptually but does not provide its
% equations. This implementation uses two parallel branches:
%   1) feature-wise attention: importance of each network-state feature
%   2) node-wise attention: importance of each node state
% Their outputs are fused and added through a residual path.

X = (S-normP.min)./(normP.max-normP.min+eps);
X = max(0,min(1,X));

% ---------------- Feature-attention branch ----------------
muF = mean(X,1);
varF = mean((X-muF).^2,1);
energyF = (muF + sqrt(varF+eps))/max(P.pmamTemperature,eps);
featureWeights = 1./(1+exp(-energyF));
featureBranch = X .* featureWeights;

% ---------------- Node-attention branch -------------------
nodeMean = mean(X,2);
nodeVar = mean((X-nodeMean).^2,2);
nodeEnergy = (nodeMean + sqrt(nodeVar+eps))/max(P.pmamTemperature,eps);
nodeWeights = 1./(1+exp(-nodeEnergy));
nodeBranch = X .* nodeWeights;

% ---------------- Parallel mixed fusion -------------------
mixed = P.pmamFeatureWeight*featureBranch + ...
        (1-P.pmamFeatureWeight)*nodeBranch;

attended = P.pmamResidualWeight*X + ...
           (1-P.pmamResidualWeight)*mixed;
attended = max(0,min(1,attended));

info.featureWeights = featureWeights;
info.nodeWeights = nodeWeights;
info.meanAttention = mean(attended(:));
end
