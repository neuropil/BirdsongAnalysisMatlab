function [outList , axisOUT, condIndex, lrIndex] = songDateReorder( inList )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


CondOrderIndex = false(length(inList),4);
for li = 1:length(inList)
    tempCond = inList{li};
    
    if ~isempty(strfind(tempCond,'Pre'))
        CondOrderIndex(li,:) = [1  0  0  0];
    elseif ~isempty(strfind(tempCond,'LMAN'))
        CondOrderIndex(li,:) = [0  1  0  0];
    elseif ~isempty(strfind(tempCond,'Infusion'))
        CondOrderIndex(li,:) = [0  0  1  0];
    elseif ~isempty(strfind(tempCond,'Lesion'))
        CondOrderIndex(li,:) = [0  0  0  1];
    end

end



for cI = 1:4
    
    switch cI
        
        case 1 % FINISH PRE 8/29/2013
            
            preDays = inList(CondOrderIndex(:,cI));
            
            if sum(~cellfun('isempty',strfind(preDays,'PreALL')))
%                 preAllIndex = find(~cellfun('isempty',strfind(preDays,'PreALL')));
                
                preAllday = preDays{~cellfun('isempty',strfind(preDays,'PreALL'))};
                preDays = preDays(cellfun('isempty',strfind(preDays,'PreALL')));
                
                preAllcheck = 1;
                
            else
                
                preAllcheck = 0;

            end
            
            dateNumVec = zeros(length(preDays),1);
            for pmd = 1:length(preDays)
                dateNumVec(pmd) = datenum(regexp(preDays{pmd},'(0|1)?[0-9]{4}','match'),'mmdd');
            end
            
            % Check for extreme differences in date % John stupidly didn't
            % include a year ; this corrects for 12/31/07 - 01/01/08
            
            [sortDates,newOrder] = sort(dateNumVec);
            preDays = preDays(newOrder);
            
            difftest = diff(sortDates);
            
            dateDiffs = find(difftest > 30);
            
            if ~isempty(dateDiffs)
                PredateOrder = [preDays(dateDiffs+1:length(preDays)) ;...
                    preDays(1:dateDiffs)];   
            else
                PredateOrder = preDays;
            end
            
            if preAllcheck == 1;  
                PredateOrder = [preAllday ; preDays]; 
            end
            
            preXaxis = num2cell(repmat('P',[length(PredateOrder),1]));
            preCIndex = ones(1,length(PredateOrder));
            prelrI = num2cell(nan(1,length(PredateOrder)));
            
        case 2
            
            lmanDays = inList(CondOrderIndex(:,cI));
            
            dateNumVec = zeros(length(lmanDays),1);
            for lmd = 1:length(lmanDays)
                dateNumVec(lmd) = datenum(regexp(lmanDays{lmd},'(0|1)?[0-9]{4}','match'),'mmdd');
            end
            
            % Check for extreme differences in date % John stupidly didn't
            % include a year ; this corrects for 12/31/07 - 01/01/08
            
            [sortDates,newOrder] = sort(dateNumVec);
            lmanDays = lmanDays(newOrder);
            
            difftest = diff(sortDates);
            
            dateDiffs = find(difftest > 30);
            
            if ~isempty(dateDiffs)
                LMdateOrder =  [lmanDays(dateDiffs+1:length(lmanDays)) ;...
                    lmanDays(1:dateDiffs)];
            else
                LMdateOrder = lmanDays;
            end
            
            LMANXaxis = num2cell(repmat('L',[length(LMdateOrder),1]));
            lmanCIndex = ones(1,length(LMdateOrder)) + 1;
            lmanlrI = num2cell(nan(1,length(LMdateOrder)));

        case 3
            
            infusionDays = inList(CondOrderIndex(:,cI));
            
            dateNumVec = zeros(length(infusionDays),1);
            for id = 1:length(infusionDays)
                dateNumVec(id) = datenum(regexp(infusionDays{id},'(0|1)?[0-9]{4}','match'),'mmdd');
            end
            
            [sortDates,newOrder] = sort(dateNumVec);
            infusionDays = infusionDays(newOrder);
            
            difftest = diff(sortDates);
            
            dateDiffs = find(difftest > 30);
            
            if ~isempty(dateDiffs)
                INdateOrder =  [infusionDays(dateDiffs+1:length(infusionDays)) ;...
                    infusionDays(1:dateDiffs)];
            else
                INdateOrder = infusionDays;
            end
            
            HVCINaxis = num2cell(repmat('I',[length(INdateOrder),1]));
            hvciCIndex = ones(1,length(INdateOrder)) + 2;
            
            hvcilrI = cell(1,length(INdateOrder));
            for di = 1:length(INdateOrder)
                if strcmp('Right', regexp(INdateOrder{di},'Right|Left','match'))
                    hvcilrI{di} = 'R';
                else
                    hvcilrI{di} = 'L';
                end
            end
            
        case 4
            
            lesionDays = inList(CondOrderIndex(:,cI));
            
            dateNumVec = zeros(length(lesionDays),1);
            for led = 1:length(lesionDays)
                dateNumVec(led) = datenum(regexp(lesionDays{led},'(0|1)?[0-9]{4}','match'),'mmdd');
            end
            
            [sortDates,newOrder] = sort(dateNumVec);
            lesionDays = lesionDays(newOrder);
            
            difftest = diff(sortDates);
            
            dateDiffs = find(difftest > 30);
            
            if ~isempty(dateDiffs)
                LNdateOrder =  [lesionDays(dateDiffs+1:length(lesionDays)) ;...
                    lesionDays(1:dateDiffs)];
            else
                LNdateOrder = lesionDays;
            end
            
            HVCLNaxis = num2cell(repmat('H',[length(LNdateOrder),1]));
            hvclCIndex = ones(1,length(LNdateOrder)) + 3;
            
            hvcllrI = cell(1,length(LNdateOrder));
            for di = 1:length(LNdateOrder)
                if strcmp('Right', regexp(LNdateOrder{di},'Right|Left','match'))
                    hvcllrI{di} = 'R';
                else
                    hvcllrI{di} = 'L';
                end
            end
            
    end
end


% FINISH NEWORDER 8/29/2013

outList = [PredateOrder ; LMdateOrder ; INdateOrder ; LNdateOrder];

axisOUT = [preXaxis ; LMANXaxis ; HVCINaxis ; HVCLNaxis];

condIndex = [preCIndex , lmanCIndex , hvciCIndex , hvclCIndex];

lrIndex = [prelrI , lmanlrI , hvcilrI , hvcllrI];