function [agents,rewardMean,lossMean] = localAACPPO(agents,data,net,P,round)
%LOCALAACPPO Adaptive actor-critic PPO local federated update.
% Includes DRND exploration and Smooth Policy Clipping.

rewardMean=zeros(P.numClients,1);
lossMean=zeros(P.numClients,1);

for c=1:P.numClients
    X=data(c).X;
    if isempty(X), continue; end

    aW=agents(c).actor.W; ab=agents(c).actor.b;
    cW=agents(c).critic.W; cb=agents(c).critic.b;

    clientLoss=0; clientReward=0;

    % Adaptive learning rates.
    health=mean(data(c).energy)/P.initialEnergy;
    lrA=P.actorLearningRate*(0.75+0.50*(1-health))/(1+0.0005*round);
    lrC=P.criticLearningRate*(0.75+0.50*(1-health))/(1+0.0005*round);

    for ep=1:P.localEpisodes
        logits=X*aW+ab;
        probs=softmaxRows(logits);
        [~,action]=max(probs,[],2);
        value=X*cW+cb;

        % Reward is tied to the PMAM state objectives.
        e=X(:,1);
        delayScore=1-X(:,3);
        signal=X(:,5);
        trafficScore=1-X(:,7);
        trust=X(:,8);
        thr=X(:,9);
        baseReward=0.24*e+0.16*delayScore+0.16*signal+ ...
                   0.12*trafficScore+0.14*trust+0.18*thr;

        intrinsic=DRND_Exploration(X,round);
        r=baseReward+P.intrinsicWeight*intrinsic;

        target=r;
        advantage=target-value;
        advantage=(advantage-mean(advantage))/(std(advantage)+eps);

        oldP=probs;
        newP=softmaxRows(X*aW+ab);
        chosenOld=zeros(size(action));
        chosenNew=zeros(size(action));
        for k=1:numel(action)
            chosenOld(k)=oldP(k,action(k));
            chosenNew(k)=newP(k,action(k));
        end

        ratio=chosenNew./(chosenOld+eps);
        clippedRatio=smoothPolicyClipping(ratio,P.ppoClip);
        coeff=clippedRatio.*advantage;

        onehot=zeros(size(probs));
        for k=1:numel(action)
            onehot(k,action(k))=1;
        end
        gradLogits=(onehot-probs).*coeff;
        gW=X'*gradLogits/size(X,1);
        gb=mean(gradLogits,1);

        gCW=X'*advantage/size(X,1);
        gCb=mean(advantage);

        aW=aW+lrA*gW;
        ab=ab+lrA*gb;
        cW=cW+lrC*gCW;
        cb=cb+lrC*gCb;

        entropy=-mean(sum(newP.*log(newP+eps),2));
        loss=mean(advantage.^2)-P.entropyWeight*entropy;
        clientLoss=clientLoss+loss;
        clientReward=clientReward+mean(r);
    end

    agents(c).actor.W=aW;
    agents(c).actor.b=ab;
    agents(c).critic.W=cW;
    agents(c).critic.b=cb;
    agents(c).localSamples=size(X,1);
    agents(c).rewardMean=clientReward/P.localEpisodes;
    agents(c).loss=clientLoss/P.localEpisodes;

    rewardMean(c)=agents(c).rewardMean;
    lossMean(c)=agents(c).loss;
end
end

function p=softmaxRows(x)
x=x-max(x,[],2);
ex=exp(x);
p=ex./(sum(ex,2)+eps);
end
