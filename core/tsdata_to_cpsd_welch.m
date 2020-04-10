function [S,f] = tsdata_to_cpsd_welch(X,fs,window,noverlap,fres,autospec)

afreq = nargin < 2 || isempty(fs);

if afreq, fs = 2*pi; end % default to angular frequency

if nargin < 3 || isempty(window), window = 128; end % pwelch default window is a bit rubbish...
if window == 0, window = []; end                    % ...but if you really want it, set window = 0;

if nargin < 4, noverlap = []; end % pwelch default noverlap is fine

if nargin < 5 || isempty(fres) % pwelch default nfft not necessarily good for spectral factorisation...
	nfft = 2*1024;
else
	if fres == 0               % ...but if you really want it, set fres = 0
		nfft = [];
	else
		nfft = 2*fres;
	end
end

if nargin < 6 || isempty(autospec), autospec = false; end

if nargin < 7 || isempty(verb), verb = 1; end

[nvars,nobs,ntrials] = size(X);

X = permute(X,[2 1 3]);

if autospec
	for i = 1:nvars
		[S(:,i),f] = pwelch(X(:,i,1),window,noverlap,nfft,fs);
	end
	for r = 2:ntrials
		for i = 1:nvars
			S(:,i) = S(:,i) + pwelch(X(:,i,r),window,noverlap,nfft,fs);
		end
	end
	S = (fs/2)*S/ntrials;
	S(1  ,:) = 2*S(1,  :);
	S(end,:) = 2*S(end,:);
else
	for i = 1:nvars
		[S(:,:,i),f] = cpsd(X(:,i,1),X(:,:,1),window,noverlap,nfft,fs);
	end
	for r = 2:ntrials
		for i = 1:nvars
			S(:,:,i) = S(:,:,i) + cpsd(X(:,i,r),X(:,:,r),window,noverlap,nfft,fs);
		end
	end
	S = (fs/2)*permute(S/ntrials,[3 2 1]);
	S(:,:,1  ) = 2*S(:,:,1  );
	S(:,:,end) = 2*S(:,:,end);
end
