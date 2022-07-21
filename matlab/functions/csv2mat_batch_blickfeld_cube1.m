function csv2mat_batch_blickfeld_cube1(fdir_lidar_bfpc, fdir_lidar_csv, fdir_save_mat)
%
%REQUIRED FUNCTION(S):
%   - load_cube1_frame_csv_blickfeld_recorder.m
%
%
%DESCRIPTION:
%   This function compiles and appends all frames of lidar data exported
%   to .csv files (using "Blickfeld Recorder), for all lidar recordings in
%   the folder. For example, if you have 10 .bfpc lidar stream files, and
%   each stream has 20 frames, after extracting the .csv files, you should
%   have 200 .csv files. Simply provide the path to the .bfpc files (which
%   is only necessary in order to determine the file prefixes of the .csv
%   files to be loaded), and the path to the .csv files. This function will
%   append and store ALL frames for each stream into a SINGLE structure. If
%   there are not extracted .csv files for a certain .bfpc file, the
%   function skips it. Each compiled structure is saved to a .mat file in
%   the user-specified path with the same file prefix as the .bfpc file.
%
%
%USAGE:
%   csv2mat_batch_blickfeld_cube1(fdir_lidar_bfpc, fdir_lidar_csv, fdir_save_mat)
%
%
%INPUTS:
%   fdir_lidar_bfpc: [str/char] path where the raw/original .bfpc stream
%                               file(s) corresponding to the extracted 
%                               .csv frames is(are) located 
%
%   fdir_lidar_csv:  [str/char] path where the extracted .csv files are
%                               (with individual frame data from each 
%                               stream) located, corresponding to the raw
%                               .bfpc files
%
%   fdir_save_mat:   [str/char] path defining where each .mat file
%                               containing the "scan" structure should be 
%                               saved. If the specified path does not already 
%                               exist, the path will be created.
%
%
%OUTPUTS:
%   None...but, additional fields are added to the "scan" structure, and
%   are described below. For information on original fields in the "scan"
%   structure, use ">> help load_cube1_frame_csv_blickfeld_recorder".
%   Below, "N" is the number of frames.
%
%     ADDITIONAL FIELDS
%     -----------------
%             nFrames: N
%     indexFrameStart: [N×1 double]
%      indexFrameStop: [N×1 double]
%           csv_files: [N×1 struct]
%           bfpc_file: 'path/to/bfpc/files/filename.bfpc'
%      dateFrameStart: [N×1 datetime]
%
%
%NOTES:
%   * The ".indexFrameStart" and ".indexFrameStop" fields are the linear
%     indices specifying the start and end of the n'th frame. For example,
%     to extract the x-coordinates of the 6th frame, you would use
%
%       >> x = scan.x(indexFrameStart(6):indexFrameStop(6));
%
%   * The ".dateFrameStart" field is the time of the FIRST point measured
%     in each frame (i.e., scan.dateStart + scan.time(scan.indexFrameStart))
%
%   * The ".csv_files" field is a structure array that is generated from
%     using the built-in "dir" function in MATLAB, with the following 
%     fields: name, folder, date, bytes, isdir, datenum. 
%
%   * If the specified path to save the MAT files does not already exist, 
%     the path will be created.
%
%
%--
%Author:       Ryan S. Mieras
%Affiliation:  University of North Carolina Wilmington
%Contact:      mierasr@uncw.edu
%Last Updated: July 2022
%Version:      '9.12.0.1975300 (R2022a) Update 3'
%


% Get listing of .bfpc binary files in user-defined folder
bin_files = dir(fullfile(fdir_lidar_bfpc,'*.bfpc'));


% For loop indices
a = 1;
% b = 3;  % use for testing
b = length(bin_files);


if isempty(bin_files)

    error('NO .BFPC FILES LOCATED IN SPECIFIED PATH FOR fdir_lidar_bfpc!')

else

    % For each scan...
    for i = a:b  % for each .bfpc file (may be multiple frames in each file)

        % Get listing of CSV files that match the .bfpc file prefix
        files = dir(fullfile(fdir_lidar_csv,[bin_files(i).name(1:end-5), '*.csv']));

        skip = false;
        if ~isempty(files)
            fprintf('[File %i of %i] Appending %3i CSV frames extracted from %s\n',i,(b-a+1),length(files),bin_files(i).name);
        else
            fprintf('--No .csv files found for %s!\n',bin_files(i).name);
            skip = true;
        end


        if ~skip

            % For each frame within a scan...
            L = nan(length(files),1);
            for j = 1:length(files)  % these are all the .csv files for a scan
                if j == 1
                    % Load first frame into scan structure
                    scan = load_cube1_frame_csv_blickfeld_recorder(fdir_lidar_csv,files(j).name);
                    L(j) = length(scan.x);  % length of data record
                else
                    scan_tmp = load_cube1_frame_csv_blickfeld_recorder(fdir_lidar_csv,files(j).name);
                    L(j) = length(scan_tmp.x);  % length of data record

                    % Append each successive frame to fields in scan
                    fields = fieldnames(scan_tmp);
                    for k = 2:length(fields)-1  % skip first and last fields (.dateStart and .units)
                        scan.(fields{k}) = [scan.(fields{k}); scan_tmp.(fields{k})];  % append next frame(s)
                    end
                    clear scan_tmp
                end
            end


            if ~isempty(files)
                % Convert to elapsed time
                scan.time = scan.time - scan.time(1);

                % Add frame indicies
                scan.nFrames = length(~isnan(L));
                scan.indexFrameStart = [];  % initialize (so it's in front of "indexFrameStop" in structure field order
                scan.indexFrameStop  = cumsum(L);
                scan.indexFrameStart = [1; scan.indexFrameStop(1:end-1) + 1];

                % Add fields for record keeping of data file sources
                scan.csv_files = files;
                scan.bfpc_file = fullfile(fdir_lidar_csv,bin_files(i).name);

                % Write scan structure to file
                disp('  > Saving...')
                fname_save = [bin_files(i).name(1:end-5) '.mat'];
                checkdir(fdir_save_mat,false);
                fstr_save = fullfile(fdir_save_mat, fname_save);
                save(fstr_save, 'scan')
                fprintf('  > SAVED: %s\n\n',fstr_save)

                clear scan
            end

        end

    end

end

end %END MAIN FUNCTION





%%
function checkdir(FDIR, varargin)
%CHECKDIR Check if a directory exists. If not, create one.
%   CHECKDIR(FDIR) checks whether or not the directory specified by the 
%   string FDIR exists. If the directory does not exist, it is created.
%   FDIR may be a relative or absolute path.
%
%   CHECKDIR(FDIR, true) will print an acknowledgment to the command
%   window, with information about whether or not a new directory was 
%   created (mostly a sanity check). 
%
%   If the 2nd input is not included, the default value is 'false' 
%   (i.e., no confirmation will be printed to the command window).
%
%--
%Author:       Ryan S. Mieras
%Affiliation:  U.S. Naval Research Laboratory
%Last Updated: April 2018
%Contact:      ryan.mieras.ctr@nrlssc.navy.mil


% Define default(s)
print_ack = false;


% Parse inputs
if nargin == 2  % user wants to print acknowledgment to command window
    
    print_ack = varargin{1};
    
    if ~islogical(print_ack)
        error('Second input must be class:logical (i.e., true or false).')
    end
    
elseif nargin > 2
    
    error('Too many input arguments!');
    
end


% Check for directory existence, and print info, if necessary
if ~exist(FDIR, 'dir')
    
    mkdir(FDIR);  % create directory
    
    if print_ack
        fprintf('Created new directory: %s\n', FDIR);
    end
    
elseif print_ack && exist(FDIR, 'dir') == 7  % returns value of 7 if it is a folder (see EXIST help)
    
    fprintf('The following directory already exists: %s\n', FDIR);
    
end

    
end  %end CHECKDIR
