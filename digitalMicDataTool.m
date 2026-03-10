%clc;

%% read
rawData = readmatrix("rawData.csv", "Delimiter", ",", "OutputType", "string");
headers = readmatrix("Headers.csv", "Delimiter", ",", "OutputType", "string");
volume = string(nan(30, 1));
count = 1;
for i = 1 : 3
    for j = 1 : 10
        volume(count, 1) = num2str(i) + ". " + num2str(j);
        count = count + 1;
    end
end

%%  process
data = string(nan(1, 1));
freq = string(nan(1, 1));
for item = 1: height(headers)                                              % reshape data with columns
    singleItem = string(nan(1, 1));
    for allItem = 1: width(rawData)
        if contains(rawData(2, allItem), headers(item, 1))
            itemHead = split(rawData(2, allItem), "@");
            if contains(itemHead, 'Sens') % compatible with sens & tone
                itemHead = [itemHead, itemHead];
            elseif contains(itemHead, 'tone')
                itemHead = [itemHead, itemHead];
            end
            dataColumn = rawData(8:height(rawData), allItem);
            dataColumn = [itemHead(2); dataColumn];
            if ismissing(singleItem)
                singleItem = dataColumn;
            else
                singleItem = [singleItem, dataColumn];
            end
        end
    end
    if ismissing(singleItem)                                               % make missingItem 30 blankRows
        singleItem = string(nan(31, 1));
    end    
    head = string(nan(height(singleItem), 1));                             % add head
    head(1, 1) = headers(item, 1);
    if height(volume) < height(singleItem) % crr volume
        head(2:31, 1) = volume; 
    end

    singleItem = [head, singleItem];
    singleItem = [nan(1, width(singleItem)); singleItem];

    theWidth = max(width(data), width(singleItem));                        % concat all test items
    A = extendArray(data, theWidth);
    B = extendArray(singleItem, theWidth);
    data = [A; B];
end

%% save
data(1, :) = [];
writematrix(data, "data.csv");

%% func
function B = extendArray(inputArray, theWidth)
    A = inputArray;
    B = string(nan(height(A), theWidth));

    B(1:height(A), 1:width(A)) = A;
end


