function [syllsOUT] = Get_Motif_Data()
% GET FIVE MOTIFS FROM FIVE BOUTS

N = 1500;
M = 900;

% global syllOUT
syllsOUT = [];

% CONSIDER HARD CODING FIRST PRE DAY*****************
% DERIVE AUTOMATED WAY OF GENERATING MOTIFS
[birdNum, date] = Get_First_PreDate;

% Data Locations
DS_LOC = 'C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\DataSet_Data\';
Bird_DS_LOC = strcat(DS_LOC,birdNum);

RAWSongs_LOC = 'C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\RawSongs\';
Bird_RAWSongs_LOC = strcat(RAWSongs_LOC,birdNum,'\Pre\',birdNum,'_',date);

MOTIF_LOC = 'C:\Users\Dr. JT\Documents\DataAnalysis\TF_Birdsong\Motif_Data\';
Bird_MOTIF_LOC = strcat(MOTIF_LOC,birdNum);

% Get first bout data set
cd(Bird_DS_LOC)
BCD_file = strcat(birdNum,'_Pre_',date,'.mat');
file2use = load(BCD_file);

wavFiles = file2use.songDataset.filename;
songDS = file2use.songDataset;

motifNum1 = randi(length(wavFiles),1);
motifNum2 = randi(length(wavFiles),1);
motifNum3 = randi(length(wavFiles),1);
motifNum4 = randi(length(wavFiles),1);

file1 = wavFiles{motifNum1}; %consider randomly selected motif number from total
file2 = wavFiles{motifNum2};
file3 = wavFiles{motifNum3};
file4 = wavFiles{motifNum4};

WNum1 = str2double(strtok(file1,'.'));
WNum2 = str2double(strtok(file2,'.'));
WNum3 = str2double(strtok(file3,'.'));
WNum4 = str2double(strtok(file4,'.'));

wavNums = cellfun(@(x) str2double(strtok(x,'.')), wavFiles);
waveFileIndex1 = find(wavNums == WNum1);
waveFileIndex2 = find(wavNums == WNum2);
waveFileIndex3 = find(wavNums == WNum3);
waveFileIndex4 = find(wavNums == WNum4);

spectroNote_sel_GUI;

    function spectroNote_sel_GUI
        cd(Bird_RAWSongs_LOC)
        % Create Figure Window
        fh = figure('Units','Pixels',...
            'Position',[50 50 N M],...
            'Menubar', 'none',...
            'numbertitle', 'off');
                
        hAxes1 = axes;
        
        set(hAxes1,...
            'Box', 'off',...
            'Tickdir','out',...
            'Units', 'Pixels',...
            'Position', [10 75 N/2 - 25 300],...
            'XTick', [],...
            'YTick', []);
        
        [amp1, fs1, ~] = wavread(file1);
        [~,F1,T1,P1] = spectrogram(amp1, 256,[],[],fs1, 'yaxis');
        
        time1 = T1*1000;
        
        PdB1   = 10*log10(P1);
        
        imagesc(time1,F1,PdB1);
        set(hAxes1,'YDir','Normal','XTick', []);
%         xlabel('time [s]');
%         ylabel('frequency [Hz]');
        
        hold on
        
        for syllN1 = 1:length(waveFileIndex1)
            plot([songDS.sylstart(waveFileIndex1(syllN1))...
                songDS.sylstart(waveFileIndex1(syllN1))], [0 15000],'r-', 'LineWidth', 2);
            plot([songDS.syldur(waveFileIndex1(syllN1)) + songDS.sylstart(waveFileIndex1(syllN1))...
                songDS.syldur(waveFileIndex1(syllN1)) + songDS.sylstart(waveFileIndex1(syllN1))], [0 15000],'b-', 'LineWidth', 2);
        end
        
        for syllNT1 = 1:length(waveFileIndex1)
            
            text(songDS.sylstart(waveFileIndex1(syllNT1)) + songDS.syldur(waveFileIndex1(syllNT1))/2, 5500,num2str(syllNT1),...
                'HorizontalAlignment','center','VerticalAlignment','middle');
        end

        %%% Spectrogram 2 %%%
        
        hAxes2 = axes;
        
        set(hAxes2,...
            'Box', 'off',...
            'Tickdir','out',...
            'Units', 'Pixels',...
            'Position', [760 75  N/2 - 25 300],...
            'XTick', [],...
            'YTick', []);
        
        [amp2, fs2, ~] = wavread(file2);
        [~,F2,T2,P2] = spectrogram(amp2, 256,[],[],fs2, 'yaxis');
        
        time2 = T2*1000;
        
        PdB2   = 10*log10(P2);
        
        imagesc(time2,F2,PdB2);
        set(hAxes2,'YDir','Normal','XTick', []);
%         xlabel('time [s]');
%         ylabel('frequency [Hz]');
        
        hold on
        
        for syllN2 = 1:length(waveFileIndex2)
            plot([songDS.sylstart(waveFileIndex2(syllN2))...
                songDS.sylstart(waveFileIndex2(syllN2))], [0 15000],'r-', 'LineWidth', 2);
            plot([songDS.syldur(waveFileIndex2(syllN2)) + songDS.sylstart(waveFileIndex2(syllN2))...
                songDS.syldur(waveFileIndex2(syllN2)) + songDS.sylstart(waveFileIndex2(syllN2))], [0 15000],'b-', 'LineWidth', 2);
        end
        
        for syllNT2 = 1:length(waveFileIndex2)
            
            text(songDS.sylstart(waveFileIndex2(syllNT2)) + songDS.syldur(waveFileIndex2(syllNT2))/2, 5500,num2str(syllNT2),...
                'HorizontalAlignment','center','VerticalAlignment','middle');
        end
        
        %%% Spectrogram 3 %%%
        
        hAxes3 = axes;
        
        set(hAxes3,...
            'Box', 'off',...
            'Tickdir','out',...
            'Units', 'Pixels',...
            'Position', [10 525 N/2 - 25 300],...
            'XTick', [],...
            'YTick', []);
        
        [amp3, fs3, ~] = wavread(file3);
        [~,F3,T3,P3] = spectrogram(amp3, 256,[],[],fs3, 'yaxis');
        
        time3 = T3*1000;
        
        PdB3 = 10*log10(P3);
        
        imagesc(time3,F3,PdB3);
        set(hAxes3,'YDir','Normal','XTick', []);
        
        hold on
        
        for syllN3 = 1:length(waveFileIndex3)
            plot([songDS.sylstart(waveFileIndex3(syllN3))...
                songDS.sylstart(waveFileIndex3(syllN3))], [0 15000],'r-', 'LineWidth', 2);
            plot([songDS.syldur(waveFileIndex3(syllN3)) + songDS.sylstart(waveFileIndex3(syllN3))...
                songDS.syldur(waveFileIndex3(syllN3)) + songDS.sylstart(waveFileIndex3(syllN3))], [0 15000],'b-', 'LineWidth', 2);
        end
        
        for syllNT3 = 1:length(waveFileIndex3)
            
            text(songDS.sylstart(waveFileIndex3(syllNT3)) + songDS.syldur(waveFileIndex3(syllNT3))/2, 5500,num2str(syllNT3),...
                'HorizontalAlignment','center','VerticalAlignment','middle');
        end        
          
        %%% Spectrogram 4 %%%
        
        hAxes4 = axes;       
        
        set(hAxes4,...
            'Box', 'off',...
            'Tickdir','out',...
            'Units', 'Pixels',...
            'Position', [760 525 N/2 - 25 300],...
            'XTick', [],...
            'YTick', []);
        
        [amp4, fs4, ~] = wavread(file4);
        [~,F4,T4,P4] = spectrogram(amp4, 256,[],[],fs4, 'yaxis');
        
        time4 = T4*1000;
        
        PdB4 = 10*log10(P4);
        
        imagesc(time4,F4,PdB4);
        set(hAxes4,'YDir','Normal','XTick', []); 
        
        hold on
        
        for syllN4 = 1:length(waveFileIndex4)
            plot([songDS.sylstart(waveFileIndex4(syllN4))...
                songDS.sylstart(waveFileIndex4(syllN4))], [0 15000],'r-', 'LineWidth', 2);
            plot([songDS.syldur(waveFileIndex4(syllN4)) + songDS.sylstart(waveFileIndex4(syllN4))...
                songDS.syldur(waveFileIndex4(syllN4)) + songDS.sylstart(waveFileIndex4(syllN4))], [0 15000],'b-', 'LineWidth', 2);
        end
        
        for syllNT4 = 1:length(waveFileIndex4)
            
            text(songDS.sylstart(waveFileIndex4(syllNT4)) + songDS.syldur(waveFileIndex4(syllNT4))/2, 5500,num2str(syllNT4),...
                'HorizontalAlignment','center','VerticalAlignment','middle');
        end

        sylls2table1 = (1:1:length(waveFileIndex1));
        sylls2table2 = (1:1:length(waveFileIndex2));
        sylls2table3 = (1:1:length(waveFileIndex3));
        sylls2table4 = (1:1:length(waveFileIndex4));
        
        syllTable1 = uitable;
        set(syllTable1,'Data',sylls2table1, 'ColumnName','Syllables1', 'Position',[10 350 N/2 - 25 60],'ColumnWidth',{35},'CellSelectionCallback',{@select_callback1});
        
        syllTable2 = uitable;
        set(syllTable2,'Data',sylls2table2, 'ColumnName','Syllables2', 'Position',[760 350 N/2 - 25 60],'ColumnWidth',{35},'CellSelectionCallback',{@select_callback2});
        
        syllTable3 = uitable;
        set(syllTable3,'Data',sylls2table3, 'ColumnName','Syllables3', 'Position',[10 810 N/2 - 25 60],'ColumnWidth',{35},'CellSelectionCallback',{@select_callback3});
        
        syllTable4 = uitable;
        set(syllTable4,'Data',sylls2table4, 'ColumnName','Syllables4', 'Position',[760 810 N/2 - 25 60],'ColumnWidth',{35},'CellSelectionCallback',{@select_callback4});
        

        function select_callback1(hObject, event_data)

            sel = event_data.Indices;     % Get selection indices (row, col)
            % Noncontiguous selections are ok
            selcols = unique(sel(:,2));  % Get all selected data col IDs
            
            selSyll1 = uitable;
            set(selSyll1,'Data',selcols','ColumnName','Motif1','Position', [10 20 N/2 - 25 40],'ColumnWidth',{50});
            %         set(handles.syllTable2,'Data',selcols,'ColumnName','Select Syllables');
            
            
            syllsOUT1 = get(selSyll1,'Data');
            feat_1 = songDS(waveFileIndex1(syllsOUT1),:);
            
            Motif_1.feature = feat_1;
            Motif_1.syllnum = syllsOUT1;
            
%             assignin('base','syllsOUT1', syllsOUT1)
%             assignin('base','feats_1',feat_1)
            
            cd(Bird_MOTIF_LOC)
            saveName = strcat(birdNum,'_Motif1.mat');
            save(saveName,'Motif_1');
            
        end
        
        function select_callback2(hObject, event_data)

            sel = event_data.Indices;     % Get selection indices (row, col)
            % Noncontiguous selections are ok
            selcols = unique(sel(:,2));  % Get all selected data col IDs
            
            selSyll2 = uitable;
            set(selSyll2,'Data',selcols','ColumnName','Motif1','Position', [760 20 N/2 - 25 40],'ColumnWidth',{50});
            %         set(handles.syllTable2,'Data',selcols,'ColumnName','Select Syllables');
            
            
            syllsOUT2 = get(selSyll2,'Data');
            feat_2 = songDS(waveFileIndex2(syllsOUT2),:);
            
            Motif_2.feature = feat_2;
            Motif_2.syllnum = syllsOUT2;
            
%             assignin('base','syllsOUT2', syllsOUT2)
%             assignin('base','feats_2',feat_2)

            cd(Bird_MOTIF_LOC)
            saveName = strcat(birdNum,'_Motif2.mat');
            save(saveName,'Motif_2');
            
        end
        
        function select_callback3(hObject, event_data)

            sel = event_data.Indices;     % Get selection indices (row, col)
            % Noncontiguous selections are ok
            selcols = unique(sel(:,2));  % Get all selected data col IDs
            
            selSyll3 = uitable;
            set(selSyll3,'Data',selcols','ColumnName','Motif1','Position', [10 470 N/2 - 25 40],'ColumnWidth',{50});
            %         set(handles.syllTable2,'Data',selcols,'ColumnName','Select Syllables');
            
            
            syllsOUT3 = get(selSyll3,'Data');
            feat_3 = songDS(waveFileIndex3(syllsOUT3),:);
            
            Motif_3.feature = feat_3;
            Motif_3.syllnum = syllsOUT3;
            
%             assignin('base','syllsOUT2', syllsOUT2)
%             assignin('base','feats_2',feat_2)

            cd(Bird_MOTIF_LOC)
            saveName = strcat(birdNum,'_Motif3.mat');
            save(saveName,'Motif_3');
            
        end
        
        function select_callback4(hObject, event_data)

            sel = event_data.Indices;     % Get selection indices (row, col)
            % Noncontiguous selections are ok
            selcols = unique(sel(:,2));  % Get all selected data col IDs
            
            selSyll4 = uitable;
            set(selSyll4,'Data',selcols','ColumnName','Motif1','Position', [760 470 N/2 - 25 40],'ColumnWidth',{50});
            %         set(handles.syllTable2,'Data',selcols,'ColumnName','Select Syllables');
            
            
            syllsOUT4 = get(selSyll4,'Data');
            feat_4 = songDS(waveFileIndex4(syllsOUT4),:);
            
            Motif_4.feature = feat_4;
            Motif_4.syllnum = syllsOUT4;
            
%             assignin('base','syllsOUT2', syllsOUT2)
%             assignin('base','feats_2',feat_2)

            cd(Bird_MOTIF_LOC)
            saveName = strcat(birdNum,'_Motif4.mat');
            save(saveName,'Motif_4');
            
        end

    end
end