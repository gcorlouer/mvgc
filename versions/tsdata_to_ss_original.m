function [svc,A,C,K,V,Z,E] = tsdata_to_ss_original(X,pf,morder,plotit,verb,gpterm)

% Estimate an (innovations form) state space model from an empirical observation
% time series using Larimore's Canonical Correlations Analysis (CCA) state
% space-subspace algorithm (W. E. Larimore, in Proc. Amer. Control Conference,
% vol. 2, IEEE, 1983).
%
% X         - observation process time series
% pf        - past/future horizons for canonical correlations
% morder    - SS model order: 'SVC' (default), 'prompt', or a positive integer
% plotit    - flag: set to true (default) to display singular values and SVC
%
% svc       - optimal model order according to Bauer's Singular Value Criterion (SVC)
% A,C,K,V   - estimated innovations form state space parameters
% Z         - estimated state process time series
% E         - estimated innovations process time series
%
% The past/future horizons pf may be supplied as a 2-vector [p,f] or a scalar p
% = f = pf. Bauer recommends setting p = f = 2*p, where p is the optimal
% VAR model order for the observation process X according to Aikaike's Information
% Criterion (AIC).
%
% If the model order morder is set to 'SVC', or empty (or unspecified), Bauer's SVC model order
% selection criterion (D. Bauer, Automatica 37, 1561, 2001) is used to estimate
% an optimal model order. If morder is set to 'prompt', the CCA singular values
% are displayed and the user is prompted to enter an (integer) model order.
% Otherwise, morder may be set to any positive integer model order <=
% n*min(p,f), where n is the number of observation variables.
%
% If anything goes wrong, a negative error code is returned in 'svc' and an error
% message in A.

[n,m,N] = size(X);

assert(all(isint(pf(:))),'past/future horizon must be a 2-vector or a scalar positive integer');
if isscalar(pf)
    p = pf;    f = pf;
elseif isvector(pf) && length(pf) == 2
    p = pf(1); f = pf(2);
else
    error('past/future horizon must be a 2-vector or a scalar positive integer');
end
assert(p+f < m,'past/future horizon too large (or not enough data)');
momax = n*min(p,f);

if nargin < 3,                    morder = [];   end % default: use Bauer's SVC model order estimate
if nargin < 4 || isempty(plotit), plotit = true; end % default: display singular values
if nargin < 5 || isempty(verb),   verb   = 0;    end
if nargin < 6,                    gpterm = [];   end

if   isempty(morder)
    useSVC = true;
    prompt = false;
elseif ischar(morder)
    if     strcmpi(morder,'SVC')
        useSVC = true;
        prompt = false;
    elseif strcmpi(morder,'prompt')
        useSVC = false;
        prompt = true;
    else
        error('model order must be ''SVC'', ''prompt'', or a positive integer <= n*min(p,f) = %d',momax)
    end
else
    assert(isscalar(morder) && isint(morder) && morder >= 0 && morder <= momax,'model order must be ''SVC'', ''prompt'', or a positive integer <= n*min(p,f) = %d',momax);
    useSVC = false;
    prompt = false;
end
if prompt, plotit = true; end

svc = 0;
A = 'something went wrong'; % fallback error message
C = [];
K = [];
V = [];
Z = [];
E = [];

X = demean(X); % subtract temporal mean

mp  = m-p;
mp1 = mp+1;
mf  = m-f;
mpf = mp1-f; % m-p-f+1

Nmp  = N*mp;
Nmp1 = N*mp1;
Nmpf = N*mpf;

Xf = zeros(n,f,mpf,N);
for k = 1:f
    Xf(:,k,:,:) = X(:,p+k:mf+k,:);
end
Xf = reshape(Xf,n*f,Nmpf);

XP = zeros(n,p,mp1,N);
for k = 0:p-1
    XP(:,k+1,:,:) = X(:,p-k:m-k,:);
end
Xp = reshape(XP(:,:,1:mpf,:),n*p,Nmpf);
XP = reshape(XP,n*p,Nmp1);

[Wf,cholp] = chol((Xf*Xf')/Nmpf,'lower');
if cholp ~= 0; svc = -1; A = 'forward weight matrix not positive definite'; return; end

[Wp,cholp] = chol((Xp*Xp')/Nmpf,'lower');
if cholp ~= 0; svc = -2; A = 'backward weight matrix not positive definite'; return; end

BETA = Xf/Xp; % 'OH' estimate: regress future on past
if ~all(isfinite(BETA(:))), svc = -3; A = 'subspace regression failed'; return; end

[~,S,U] = svd(Wf\BETA*Wp); % SVD of CCA-weighted OH estimate

sval    = diag(S); % the singular values
nparms  = 2*n*(1:momax)';                                    % number of free parameters (Hannan & Deistler, see also Bauer 2001)
SVC     = -log(1-[sval(2:end);0]) + nparms*(log(Nmpf)/Nmpf); % Bauer's Singular Value Criterion

% Display SVC if requested

if plotit
	if ischar(gpterm)
		display_morder_gp(SVC,svc,sval,gpterm);
	else
		display_morder(SVC,svc,sval);
	end
end

if nargout < 2, return; end % just wanted model order (got SVC)

% Now we select the model order that is actually used

if prompt
    r = prompt_morder(svc,momax);
end

if useSVC
	r = svc;
elseif ~prompt
	r = morder;
end

if verb > 0
	fprintf('\nSS model order selection:');
	fprintf('\n\tSVC = %d',svc)
	if useSVC
		fprintf(' *** selected\n',r)
	elseif prompt
		fprintf('\n\tprm = %d *** selected\n',r)
	else
		fprintf('\n\tusr = %d *** selected\n',r)
	end
end

Z = reshape((diag(sqrt(sval(1:r)))*U(:,1:r)'/Wp)*XP,r,mp1,N);   % Kalman states estimate; note that Z starts at t = p+1, has length mp1 = m-p+1

% Calculate model parameters by regression

C = reshape(X(:,p+1:m,:),n,Nmp)/reshape(Z(:,1:mp,:),r,Nmp);     % observation matrix
if ~all(isfinite(C(:))), r = -4; A = 'C parameter estimation failed'; return; end

E = reshape(X(:,p+1:m,:),n,Nmp) - C*reshape(Z(:,1:mp,:),r,Nmp); % innovations
V = (E*E')/(Nmp-1);                                           % innovations covariance matrix (unbiased estimate)

AK = reshape(Z(:,2:mp1,:),r,Nmp)/[reshape(Z(:,1:mp,:),r,Nmp);E];
if ~all(isfinite(AK(:))), r = -5; A = 'A/K parameter estimation failed'; return; end

A = AK(:,1:r);                                                  % state transition matrix
K = AK(:,r+1:r+n);                                              % Kalman gain matrix

E = reshape(E,n,mp,N);

end

function display_morder(SVC,svc,sval)

    monum = length(sval);
    mos = (1:monum)';

    subplot(2,1,1); % singular values
    bar(mos,sval,'b');
    xlim([0 monum+1]);
    xlabel('model order');
    ylabel('singular value');
    title('singular values');

    subplot(2,1,2); % SVC
    icmin = min(SVC);
    icmax = max(SVC);
    SVC = (SVC-icmin)/(icmax-icmin); % scale between 0 and 1
    plot(mos,SVC);
    grid on
    xlim([0 monum+1]);
    xlabel('model order');
    ylabel('information criterion (scaled)');
    title(sprintf('SVC (optimum model order = %d)',svc));

	axes('Units','Normal');
	h = title(sprintf('SS model order selection\n\n'),'FontSize',13);
	set(gca,'visible','off')
	set(h,'visible','on')

end

function display_morder_gp(SVC,svc,sval,gpterm)

    monum = length(sval);
    mos = (1:monum)';

    gpstem = fullfile(tempdir,'ssmo');
    gp_write(gpstem,[mos,sval,SVC]);
    gp = gp_open(gpstem,gpterm,[Inf 0.6]);
    fprintf(gp,'datfile = "%s.dat"\n',gpstem);
    fprintf(gp,'set multiplot title "SS model order selection\\\n" layout 2,1\n');
    fprintf(gp,'set lmargin 12\n');
    fprintf(gp,'set rmargin 4\n');
    fprintf(gp,'set border 3\n');
    fprintf(gp,'set xtics nomirror\n');
    fprintf(gp,'set xr [0.5:%f]\n',monum+0.5);
    fprintf(gp,'set yr [0:]\n');
    fprintf(gp,'set grid\n');
    fprintf(gp,'set title "Singular values"\n');
    fprintf(gp,'set ytics 0.2 nomirror\n');
    fprintf(gp,'set xlabel "model order\\n"\n');
    fprintf(gp,'set ylabel "singular value"\n');
    fprintf(gp,'plot datfile u 1:2 w boxes fs solid 0.25 not\n');
    fprintf(gp,'set title "SVC: optimal model order = %d"\n',svc);
    fprintf(gp,'set ytics auto nomirror\n');
    fprintf(gp,'set xlabel "model order"\n');
    fprintf(gp,'set ylabel "information criterion"\n');
    fprintf(gp,'plot datfile u 1:3 w linesp pt 6 not\n');
    fprintf(gp,'unset multiplot\n');
    gp_close(gp,gpstem,gpterm);

end

function r = prompt_morder(svc,momax)

    while true
        mo_user = input(sprintf('\nRETURN for SVC model order = %d, or enter a numerical model order <= %d: ',svc,momax),'s');
        if isempty(mo_user), r = svc; return; end
        r = str2double(mo_user);
        if ~isnan(r) && isscalar(r) && floor(r) == r && r > 0 && r <= momax, return; end
        fprintf(2,'ERROR: ');
    end

end
