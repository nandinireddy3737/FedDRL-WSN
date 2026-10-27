function clusters=formClusters(net,CHs,P)
%FORMCLUSTERS Assign each alive non-CH node to nearest CH.

N=P.N;
clusters=cell(numel(CHs),1);

alive=find(net.energy>P.energyDeathThreshold);
if isempty(CHs), return; end

for k=1:numel(CHs)
    clusters{k}=CHs(k);
end

members=setdiff(alive,CHs);

if isempty(members), return; end

D=pdist2(net.pos(members,:),net.pos(CHs,:));
[~,ix]=min(D,[],2);

for i=1:numel(members)
    clusters{ix(i)}=[clusters{ix(i)} members(i)];
end
end
