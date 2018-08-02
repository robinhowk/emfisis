function writeToCdf( cdfFolder, date, cdfDataMaster, cdfInfoMaster, data, numRecords, deltaT )
  filename = sprintf('%s/rbsp-a_chorus-elements_%04d%02d%02d_v1.0.0', cdfFolder, date.Year, date.Month, date.Day);

  % initialize static variables
  timeOffset = 0:deltaT:(98*deltaT);
  timeOffsetLabel = cdfDataMaster{3};

  varlist{2 * length(cdfInfoMaster.Variables(:,1))} = {};
  datatypes{2 * length(cdfInfoMaster.Variables(:,1))} = {};
  % construct variable list, cell array for cdf file
  for i = 1:length(cdfInfoMaster.Variables(:,1))
    varlist{2 * i - 1} = cdfInfoMaster.Variables{i,1};
    datatypes{2 * i - 1} = cdfInfoMaster.Variables{i, 1};
    datatypes{2 * i} = cdfInfoMaster.Variables{i, 4};
  end

  varlist{2} = data.chorusEpoch(1:numRecords);
  varlist{4} = timeOffset;
  varlist{6} = timeOffsetLabel;
  varlist{8} = data.frequency(1:numRecords, :);
  varlist{10} = data.psd(1:numRecords, :);
  varlist{12} = data.sweeprate(1:numRecords);
  varlist{14} = data.burst(1:numRecords);
  varlist{16} = data.chorusIndex(1:numRecords);

  % construct recordbound variable list
  rbvars = {cdfInfoMaster.Variables{:,1}};
  for i = length(cdfInfoMaster.Variables(:,1)):-1:1
     if (strncmpi(cdfInfoMaster.Variables{i,5}, 'f', 1) == 1)
         rbvars(:,i) = [];
     end
  end

  spdfcdfwrite(filename, varlist, ...
          'GlobalAttributes', cdfInfoMaster.GlobalAttributes, ...
          'VariableAttributes', cdfInfoMaster.VariableAttributes, ...
          'RecordBound', rbvars, ...
          'Vardatatypes', datatypes, ...
          'CDFLeapSecondLastUpdated', cdfInfoMaster.FileSettings.LeapSecondLastUpdated);
end