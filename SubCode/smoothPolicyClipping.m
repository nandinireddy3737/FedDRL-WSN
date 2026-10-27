function y = smoothPolicyClipping(ratio,clipValue)
%SMOOTHPOLICYCLIPPING Smooth approximation to PPO clipping.
lo=1-clipValue;
hi=1+clipValue;
mid=(lo+hi)/2;
half=(hi-lo)/2;
y=mid+half*tanh((ratio-mid)/(half+eps));
end
