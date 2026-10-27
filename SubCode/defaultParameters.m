function P = defaultParameters()
%DEFAULTPARAMETERS Parameters for updated FedDRL-DA-MOO WSN.
% Architecture follows the new abstract:
% PMAM -> A-AC-PPO + DRND -> ADWIN/FedAvg -> E-MOSSO CH selection
% and E-MOSSO hyperparameter optimization. Routing is performed by A-AC-PPO.

P.N = 100;
P.areaX = 100;
P.areaY = 100;
P.numBS = 3;
P.BS = [10 50; 50 90; 90 50];

% Energy/radio model
P.initialEnergy = 0.5;
P.energyDeathThreshold = 1e-8;
P.Eelec = 50e-9;
P.Efs = 10e-12;
P.Emp = 0.0013e-12;
P.EDA = 5e-9;
P.packetBits = 4000;
P.controlBits = 200;
P.d0 = sqrt(P.Efs/P.Emp);
P.maxCommunicationDistance = 80;

% Dynamic network state (9 features in the new abstract)
% [energy, distance, delay, degree, signal, mobility, traffic, trust, throughput]
P.inputDim = 9;
P.maxTraffic = 1.0;
P.maxMobility = 1.5;
P.maxDelay = 1.0;
P.minTrust = 0.05;

% PMAM
P.pmamTemperature = 0.70;
P.pmamResidualWeight = 0.50;
P.pmamFeatureWeight = 0.50;
P.attentionDim = P.inputDim;

% Simulation
P.rounds = 3000;
P.minAliveNodes = 1;
P.displayEvery = 25;

% Federated A-AC-PPO
P.numClients = 5;
P.localEpisodes = 5;
P.actorLearningRate = 0.020;
P.criticLearningRate = 0.025;
P.gamma = 0.95;
P.lambdaGAE = 0.90;
P.ppoClip = 0.20;
P.entropyWeight = 0.01;
P.intrinsicWeight = 0.05;
P.policyDim = 5;

% Smooth clipping sharpness
P.smoothClipBeta = 5.0;

% ADWIN
P.adwinDelta = 0.002;
P.adwinMinWindow = 12;
P.adwinMaxWindow = 80;
P.driftAdaptNoise = 0.01;
P.driftAggregationAlpha = 0.75;

% E-MOSSO CH selection
P.mossoPopulation = 25;
P.mossoIterations = 30;
P.numCHTarget = 20;       % 20% for N=100; adjusted automatically below
P.minCHRatio = 0.05;
P.maxCHRatio = 0.30;
P.targetCHRatio = 0.20;
P.minCH = max(2,round(P.minCHRatio*P.N));
P.maxCH = max(P.minCH+1,round(P.maxCHRatio*P.N));
P.numCHTarget = max(P.minCH,min(P.maxCH,round(P.targetCHRatio*P.N)));

% New-abstract CH objectives:
% energy, distance, degree, signal, traffic, trust, throughput
P.chWeights = [0.24 0.18 0.12 0.12 0.10 0.12 0.12];

% E-MOSSO hyperparameter optimization
% The abstract does not prescribe the exact hyperparameters; these four
% are implementation choices for the research prototype.
P.hyperOptEnabled = true;
P.hyperOptEvery = 100;
P.hyperPop = 16;
P.hyperIterations = 12;
P.actorLRBounds = [0.005 0.040];
P.criticLRBounds = [0.005 0.050];
P.ppoClipBounds = [0.10 0.30];
P.intrinsicBounds = [0.01 0.12];

% Routing decision weights generated from global A-AC-PPO policy
P.routeEnergyWeight = 0.24;
P.routeDistanceWeight = 0.24;
P.routeSignalWeight = 0.18;
P.routeTrustWeight = 0.18;
P.routeTrafficWeight = 0.16;

% Output
P.outputDir = 'FedDRL_DA_MOO_Output';
end
