function agents = federatedAggregation(agents,P,driftDetected)
%FEDERATEDAGGREGATION Weighted FedAvg; drift triggers adaptive blending.

weights=zeros(numel(agents),1);
for c=1:numel(agents)
    weights(c)=max(1,agents(c).localSamples);
end
weights=weights/(sum(weights)+eps);

globalAW=zeros(size(agents(1).actor.W));
globalAb=zeros(size(agents(1).actor.b));
globalCW=zeros(size(agents(1).critic.W));
globalCb=0;

for c=1:numel(agents)
    globalAW=globalAW+weights(c)*agents(c).actor.W;
    globalAb=globalAb+weights(c)*agents(c).actor.b;
    globalCW=globalCW+weights(c)*agents(c).critic.W;
    globalCb=globalCb+weights(c)*agents(c).critic.b;
end

if driftDetected
    alpha=P.driftAggregationAlpha;
else
    alpha=1.0;
end

for c=1:numel(agents)
    agents(c).actor.W=alpha*globalAW+(1-alpha)*agents(c).actor.W;
    agents(c).actor.b=alpha*globalAb+(1-alpha)*agents(c).actor.b;
    agents(c).critic.W=alpha*globalCW+(1-alpha)*agents(c).critic.W;
    agents(c).critic.b=alpha*globalCb+(1-alpha)*agents(c).critic.b;
end
end
