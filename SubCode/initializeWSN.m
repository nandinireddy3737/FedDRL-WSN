function net = initializeWSN(P)
%INITIALIZEWSN Create multi-BS WSN.

net.pos = [rand(P.N,1)*P.areaX, rand(P.N,1)*P.areaY];
net.energy = P.initialEnergy*ones(P.N,1);
net.initialEnergy = net.energy;
net.nodeId = (1:P.N)';
net.mobility = zeros(P.N,1);
net.prevPos = net.pos;
net.packetQueue = zeros(P.N,1);
net.totalSent = zeros(P.N,1);
net.totalReceived = zeros(P.N,1);
net.failedLinks = zeros(P.N,1);
net.successfulLinks = zeros(P.N,1);
net.lastCH = zeros(P.N,1);
net.lastCluster = zeros(P.N,1);
net.trust = 0.8 + 0.2*rand(P.N,1);
net.signal = ones(P.N,1);
net.delay = zeros(P.N,1);
net.throughput = zeros(P.N,1);
net.round = 0;
end
