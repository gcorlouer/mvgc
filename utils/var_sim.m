%% Simulate MVAR model
function [tsdata,var_coef,corr_res] = var_sim(tsdim, morder,nobs, specrad, g, w, ntrials)
%% Argunents
% connect_matrix: matrix of G causal connections
% specrad: spectral radius
% nobs : number of observations
% g = -log(det(R)) where R is the correlation variance exp see corr_rand_exponent
% g is residual multi-information (g = -log|R|): g = 0 yields zero correlation
% w : decay factor of var coefficients
%% 
if nargin < 4,       specrad = 0.98; end %generic value that is neurally plausible
if nargin < 5,       g = []; end 
if nargin < 6,       w = []; end
if nargin < 7, ntrials = 1; end

connect_matrix=cmatrix(tsdim); %generate random causalities
var_coef = var_rand(connect_matrix,morder,specrad,w); %generate ranodm VAR coeffictients
corr_res = corr_rand(tsdim,g); %gemerate ramdom residuas
tsdata = var_to_tsdata(var_coef,corr_res,nobs,ntrials); 
end