function intrinsic = DRND_Exploration(X,round)
%DRND_EXPLORATION Random Network Distillation-style novelty score.
persistent Wtarget
if isempty(Wtarget) || size(Wtarget,1)~=size(X,2)
    Wtarget = randn(size(X,2),3);
end

% Fixed target representation
target = tanh(X*Wtarget);

% Predictor changes slightly over time to mimic learned novelty model.
Wp = Wtarget/(1+0.01*round) + 0.01*sin(round)*ones(size(Wtarget));
pred = tanh(X*Wp);

err = mean((target-pred).^2,2);
intrinsic = (err-min(err))/(max(err)-min(err)+eps);
end
