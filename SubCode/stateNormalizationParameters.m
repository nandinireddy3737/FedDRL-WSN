function N = stateNormalizationParameters(P)
%STATENORMALIZATIONPARAMETERS Limits for the 9 new-abstract state features.
% [energy, distance, delay, degree, signal, mobility, traffic, trust, throughput]

N.min = [0 0 0 0 0 0 0 0 0];
N.max = [P.initialEnergy sqrt(P.areaX^2+P.areaY^2) ...
         P.maxDelay P.N 1 P.maxMobility P.maxTraffic 1 1];
end
