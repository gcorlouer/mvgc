%% Plot autospec on a log scale
function plot_logautocpsd(cpsd,f,fs,nchans)
loglog(f,cpsd);
xlabel('frequency (Hz)');
ylabel('power spectral density');
grid on
chan_names=cell(nchans,1);
for i=1:nchans
    chan_names(i)={['chan',num2str(i)]};
end
if nchans <= 40
    legend(chan_names);
end