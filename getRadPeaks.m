function [chorusAngles, sweeprates] = getRadPeaks(peakLabels, numPeaks, mu1)
  chorusAngles = zeros(numPeaks, 1);
  sweeprates = zeros(numPeaks, 1);
  for i = 1:numPeaks
    peakMask = peakLabels == i;
    radimage = radon(peakMask);
    [~, alpha] = max(max(radimage));
    chorusAngles(i) = 90 - alpha;
    sweeprates(i) = mu1 * tand(90 - alpha);
  end
end