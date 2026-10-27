function agents = initializeFedDRL(P,~)
%INITIALIZEFEDDRL Initialize federated actor-critic clients for PMAM states.

for c=1:P.numClients
    agents(c).actor.W = 0.05*randn(P.attentionDim,P.policyDim);
    agents(c).actor.b = zeros(1,P.policyDim);

    agents(c).critic.W = 0.05*randn(P.attentionDim,1);
    agents(c).critic.b = 0;

    agents(c).localSamples = 0;
    agents(c).rewardMean = 0;
    agents(c).loss = 0;
end
end
