function clientData = makeFederatedClientData(attended,net,P)
%MAKEFEDERATEDCLIENTDATA Partition attention-enhanced states across clients.

N = size(attended,1);
edges = round(linspace(1,N+1,P.numClients+1));

for c=1:P.numClients
    idx = edges(c):edges(c+1)-1;
    clientData(c).X = attended(idx,:);
    clientData(c).idx = idx;
    clientData(c).energy = net.energy(idx);
    clientData(c).trust = net.trust(idx);
end
end
