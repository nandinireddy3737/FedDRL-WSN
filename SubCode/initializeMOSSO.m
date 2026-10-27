function pop=initializeMOSSO(popSize,nCandidates,target)
%INITIALIZEMOSSO Initialize binary salp population.

pop=false(popSize,nCandidates);
for i=1:popSize
    idx=randperm(nCandidates,target);
    pop(i,idx)=true;
end
end
