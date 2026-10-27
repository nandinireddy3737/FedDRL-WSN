function [state,detected] = ADWIN_DriftDetection(state,value,P)
%ADWIN_DRIFTDETECTION ADWIN-style adaptive window drift detector.
%
% The window shrinks when two subwindows have significantly different
% means. This is a practical MATLAB implementation of the ADWIN idea.

state.window(end+1)=value;
if numel(state.window)>P.adwinMaxWindow
    state.window=state.window(end-P.adwinMaxWindow+1:end);
end

detected=false;

if numel(state.window)<P.adwinMinWindow
    state.lastDetected=false;
    return;
end

w=state.window;
n=numel(w);

% Test several split points.
for cut=max(5,floor(n*0.35)):min(n-5,ceil(n*0.65))
    w0=w(1:cut);
    w1=w(cut+1:end);

    n0=numel(w0); n1=numel(w1);
    mu0=mean(w0); mu1=mean(w1);
    m=1/(1/n0+1/n1);

    epsCut = sqrt((1/(2*m))*log(4/P.adwinDelta));

    if abs(mu0-mu1)>epsCut
        state.window=w1;
        detected=true;
        break;
    end
end

state.lastDetected=detected;
end
