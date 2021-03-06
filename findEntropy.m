% To run this, create your probability distributions as (1 by m) arrays
% And then load them all into a cell array called transitionProbabilities.




% Here is an example for a bird with 3 days of singing and 10 transitions
% where the transitions are created randomly via the rand command. But in 
% your case, you would have different values to fill in.
% Type in the at command prompt the following:

%             day1Probs = rand(1,10);
%             day2Probs = rand(1,10);
%             day3Probs = rand(1,10);
%             transitionProbabilities=cell(3,1);
%             transitionProbabilities{1}=day1Probs;
%             transitionProbabilities{2}=day2Probs;
%             transitionProbabilities{3}=day3Probs;
%             findEntropy(transitionProbabilities)

% Contributed by Dr. Arij Dou

function allEntropies = findEntropy(transitionProbabilities)

% transitionProbabilities is a cell array of size k by 1
% where k is the number of days. Each row of this cell array
% is a cell array by itself containing the probs for that particular day.

numDays = size(transitionProbabilities,1);
allEntropies = zeros(numDays,1);
    for dayI = 1:numDays
        probs = transitionProbabilities{dayI};
        numSylTrans = size(probs,2);
        entropy = 0;
        for tranI = 1:numSylTrans
            entropy = entropy + probs(tranI)*log2(probs(tranI));
        end
        allEntropies(dayI)=entropy;
    end

end 