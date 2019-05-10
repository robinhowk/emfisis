function [] = compare_resolutions(mat_path, burstname)
load(mat_path);
paramfilename = setparam(tspec, fspec, 15);
load(paramfilename);

sub_rows = 3;
sub_cols = 2;


% Display behavior of original resolution

fr = 1;
tr = 2;

runFile;

image = figure();

splot = zeros(6, 1);
i = 1;
splot1 = subplot(sub_rows, sub_cols, i);
imagesc(tspec, fspec, spect); colormap(splot1, jet); title(colorbar, 'Magnitude (dB)');
caxis([-160, -30]); set(splot1, 'ydir', 'normal');
title(splot1, sprintf('Original resolution\n%s', datestr(timestamp)));
xlabel(splot1, 'Time (s)'); ylabel(splot1, 'Frequency (Hz)');

i = 3;
splot2 = subplot(sub_rows, sub_cols, i);
histogram(sweeprates, 'BinWidth', 500);
xlabel(splot2, 'Sweep Rate (Hz/s)'); ylabel(splot2, 'Spine Count');
title(splot2, "Sweep Rates");

i=5;
splot3 = subplot(sub_rows, sub_cols, i);
imagesc(tspec, fspec, spect); colormap(splot3, jet); title(colorbar, 'Magnitude (dB)');
caxis([-160, -30]); set(splot3, 'ydir', 'normal');
title(splot3, 'Original with spines');
xlabel(splot3, 'Time (s)'); ylabel(splot3, 'Frequency (Hz)');
hold on;
[f, t] = find(spines == 1);
plot(tspec(t), fspec(f), 'ks', 'markersize', 2);
hold off;


% Display behavior with enhanced resolution

fspec = fspec(1):8:fspec(end);
[~,fspec,tspec,spect] = spectrogram(BuData, 2048, 2048-256, fspec, 35000);
spect = 10 * log10(spect);
paramfilename = setparam(tspec, fspec, 30);
load(paramfilename);
burstname = sprintf('%s_enhanced', burstname)

fr = 1;
tr = 2;

runFile

i = 2;
splot4 = subplot(sub_rows, sub_cols, i);
imagesc(tspec, fspec, spect); colormap(splot4, jet); title(colorbar, 'Magnitude (dB)');
caxis([-160, -30]); set(splot4, 'ydir', 'normal');
title(splot4, sprintf('Enhanced resolution\n%s', datestr(timestamp)));
xlabel(splot4, 'Time (s)'); ylabel(splot4, 'Frequency (Hz)');

i = 4;
splot5 = subplot(sub_rows, sub_cols, i);
histogram(sweeprates, 'BinWidth', 500);
xlabel(splot5, 'Sweep Rate (Hz/s)'); ylabel(splot5, 'Spine Count');
title(splot5, "Sweep Rates");

i=6;
splot6 = subplot(sub_rows, sub_cols, i);
imagesc(tspec, fspec, spect); colormap(splot6, jet); title(colorbar, 'Magnitude (dB)');
caxis([-160, -30]); set(splot6, 'ydir', 'normal');
title(splot6, 'Enhanced with spines');
xlabel(splot6, 'Time (s)'); ylabel(splot6, 'Frequency (Hz)');
hold on;
[f, t] = find(spines == 1);
plot(tspec(t), fspec(f), 'ks', 'markersize', 2);
hold off;

set(gcf, 'Position', [50, 50, 1600, 900]);
[~, name, ~] = fileparts(mat_path);
pause(1)
saveas(image, sprintf('images/resolution comparison/green/%s.jpg', name));
close
end