function agents = adaptAfterDrift(agents,P)
%ADAPTAFTERDRIFT Trigger adaptive local-policy updates after ADWIN drift.

for c=1:numel(agents)
    agents(c).actor.W=agents(c).actor.W + ...
        P.driftAdaptNoise*randn(size(agents(c).actor.W));
    agents(c).actor.b=agents(c).actor.b + ...
        0.5*P.driftAdaptNoise*randn(size(agents(c).actor.b));
    agents(c).critic.W=agents(c).critic.W + ...
        0.5*P.driftAdaptNoise*randn(size(agents(c).critic.W));
end
end
