function policy = getGlobalPolicy(agents)
%GETGLOBALPOLICY Convert the global A-AC-PPO actor to routing preferences.

W=zeros(size(agents(1).actor.W));
b=zeros(size(agents(1).actor.b));
for c=1:numel(agents)
    W=W+agents(c).actor.W;
    b=b+agents(c).actor.b;
end
W=W/numel(agents);
b=b/numel(agents);

s=mean(abs(W),1)+abs(b);
s=s/(sum(s)+eps);

% Five policy outputs are interpreted only as routing priorities.
policy.energy=s(1);
policy.distance=s(2);
policy.signal=s(3);
policy.trust=s(4);
policy.traffic=s(5);
end
