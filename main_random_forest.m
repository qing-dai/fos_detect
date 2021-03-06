%% import all data

% select multiple image and tag files
% change filepath if needed
[filename,pathname] = uigetfile('../data/DH/cfos/*.tif', ...
   'Select image file', 'MultiSelect', 'on' );

% store image file paths in a vector
cfos_image_path_vector = strcat(pathname, filename(:)); 


[filename,pathname] = uigetfile('../data/DH/tag/*.xlsx', ...
    'Select image file', 'MultiSelect' , 'on');

% store image file paths in a vector
tag_path_vector = strcat(pathname, filename(:));

%% 
% randomly select 10 as test images from all images 
m = length(cfos_image_path_vector);

% track images by their indices
test_index = randsample(1:m, 10);

% store test images and test tag path in a vector
test_image_path_vector = cfos_image_path_vector(test_index);
test_tag_path_vector = tag_path_vector(test_index);

% store train images and test tag path in a vector
train_image_path_vector = setdiff(cfos_image_path_vector,test_image_path_vector );
train_image_tag_vector = setdiff(tag_path_vector,test_tag_path_vector );

%% extract features 
   
% initialization
training_Label_vector = [];      
training_Feature_vector = [];
 

tic
for i = 1: length(train_image_tag_vector)
    % track time
    remain_time = (toc / i) * (length(train_image_tag_vector)-i);
    
    % track elapsed time
    s = sprintf(' %d / %d \n time used: %.2f \n time remains %.2f \n', i,length(train_image_tag_vector), toc, remain_time);     
    fprintf(s);  
    
%     % extract patches from each image
%     [ Labels, training_BW_patch, ~, training_Gray2_patch]...                       
%         = create_pixel_features(train_image_path_vector{i}, train_image_tag_vector{i}, 'cfos');
   
    % extract features and labels
    [Features, Labels] = extract_feature_and_import_tags...
       (train_image_path_vector{i}, train_image_tag_vector{i}, 'cfos');
    
    
    
    
%     BW_patch_vector = [BW_patch_vector   BW_patch];
%     Gray2_patch_vector = [Gray2_patch_vector   Gray2_patch];  

    % concatenate
    training_Label_vector = [training_Label_vector;  Labels]; 
    
    training_Feature_vector = [training_Feature_vector; Features];
end
 
% store features and labels in a featureData structure for convinience
% Feature vector: m*n, where m is number of patches, and n is number of
% features
% Label vector: m*1
featureData = struct('Feature',training_Feature_vector, 'Label', training_Label_vector );

%% save features

% save featureData for later use if needed

% save('/Users/qingdai/Desktop/fos_detection/data/featureData(Shape + Texture + LBP + HOG_25).mat' , ...
%     'featureData');

%% load features

% load saved featureData if needed

% feature_path = '/Users/qingdai/Desktop/fos_detection/data/featureData(Shape + Texture + LBP + HOG_25).mat';
% a = load(feature_path);
% a = a.featureData;
% 
% training_Feature_vector = a.Feature;
% training_Label_vector = a.Label;
% 


%% set indices and cross validation

% get total number of patches
m = length(training_Feature_vector);

% find the indices of all positive signals
positive_index = find(training_Label_vector);

% find the indices of all negative signals by exclusion
negative_index = setdiff(1:m, positive_index);

% randomly choose subsamples to balance data
 negInd = randsample(negative_index, length(positive_index));


% combine and shuffle subsample
total_index = [positive_index; negInd'];
total_index = total_index(randperm(length(total_index)));

% set k-fold validation
k = 5;
cv = cvpartition(total_index, 'kfold', k);

%% train and test 
% initialze a matrix to store result
result = zeros(9,k);

for i = 1:k
    
    disp(i)
    
    % In each CV fold, divide all training into two subsets: training set
    % and validation set
    
    % store indices for training set and validation set
    trainInd = total_index(training(cv,i));
    valInd  = total_index(test(cv,i));
    
    % import (k-1)/k of training features and training labels from all
    % training data
    trainFeatures = training_Feature_vector(trainInd,:);
    trainLabels = training_Label_vector(trainInd(1:end), :);
    
    % import 1/k of validation features and validation labels from all
    % training data
    valFeatures = training_Feature_vector(valInd(1:end), :);
    valLabels = training_Label_vector(valInd(1:end), :);
    
    % train model
    
    % random number generation for RF algorithm
    rng(1);
    
    % n: number of trees in RF algorithm
    n = 200;
    Model = TreeBagger(n,trainFeatures,trainLabels,'OOBPrediction',...
        'On', 'Method','classification');
  
    % predict using validation set
    [predict_labels, score, stdevs] = predict(Model,valFeatures);
    predict_labels = str2double(predict_labels);
    
    % check validation accuracy
    % r stores tp, fp, fn, precision, recall, accuracy, and print to the
    % console
    [r, f1_score] = check_accuracy(valLabels, predict_labels);
    
    % ROC curve
    [X,Y,T,AUC,OPTROCPT,SUBY] = perfcurve(valLabels,score(:,2), 1, 'XCrit','fall', 'YCrit','sens');
    figure;plot(X,Y);
    
    % Precision/Recall curve
    [X2,Y2,T,AUC2,OPTROCPT,SUBY] = perfcurve(valLabels,score(:,2), 1, 'XCrit','reca', 'YCrit','prec');
    figure;plot(X2,Y2);
    
    result(:,i) =  [r(1:end); AUC; AUC2; f1_score];

    % visualize Random Forest model
%      view(Model.Trees{1},'Mode','graph')
%      view(Model.Trees{1})

%      figure;
%      oobErrorBaggedEnsemble = oobError(Model);
%      plot(oobErrorBaggedEnsemble)
%      xlabel 'Number of grown trees';
%      ylabel 'Out-of-bag classification error';
%    	
    	
end

disp('avg');
avg = mean(result,2);
disp(avg);



%% save model

% save('/Users/qingdai/Desktop/fos_detection/model/RF200_min25_(Shape+texture+LBP+HOG)_+=-=4959' , ...
%     'Model');


%% select model
% choose saved model if needed

% [filename,pathname] = uigetfile('../model/*.mat', ...
%    'Select model' );
% modelPath = [pathname, filename];
% a = load(modelPath);
% predict_model = a.Model;

predict_model = Model;

%% test model

% initialization
test_Features = [];
test_Labels = [];
predict_Labels = [];
score = [];
result = [];

for i = 1:length(test_image_path_vector)
   disp(i)
   
   % extract features and labels from the vectors created in the second
   % section
   [Features, Labels] = extract_feature_and_import_tags...
         (test_image_path_vector{i}, test_tag_path_vector{i}, 'cfos');
         
    % concatenate true labels among iterations
    test_Labels = [test_Labels; Labels];
    
    
    [pre, s] = predict(predict_model,Features);
    pre = str2double(pre);
    
    % concatenate predict labels among iterations
    predict_Labels = [predict_Labels ;pre];
   
    % concatenate score/probability among iterations
    score = [score; s];
    
    % check test accuracy
    % r stores tp, fp, fn, precision, recall, accuracy,f1_score and print to the
    % console
    [r, f1_score] = check_accuracy(Labels, pre);
    r = [r;f1_score];
    result = [result r]; 

    % total number of positive candidates predicted 
    num_of_predict(i) = length(find(pre));
    
    % total number of true positive candidates
    num_of_true(i) = length(find(Labels));
    


end

% plot true/predicted number of positive signals
x = 1:10;
figure;plot(x,num_of_predict, x, num_of_true );
xlabel('image index')
ylabel('number of positive signals')

avg = mean(result, 2);



% ROC Curve
% TPR vs FPR = sensitivity vs (1-specificity) = TP/(TP+FN) vs FP/(FP+TN)
[X,Y,T,AUC,OPTROCPT,SUBY] = perfcurve(test_Labels,score(:,2), 1,'XCrit','fall', 'YCrit','sens');
figure;plot(X,Y);
xlabel('False positive rate')
ylabel('True positive rate')

% Precision/Recall curve
% TP/(TP+FP) vs TP/(TP+FN) 
[X2,Y2,T,AUC2,OPTROCPT,SUBY] = perfcurve(test_Labels,score(:,2), 1, 'XCrit','reca', 'YCrit','prec');
figure;plot(X2,Y2);
xlabel('Recall')
ylabel('Precision')
%% analyze
% visualize result on image
cfos_mislabel = check_mislabeled(test_image_path_vector{i}, Labels, pre);
% % tdt_midlabel = check_mislabeled(tdt_test_image_path, tdt_test_label_vector, tdt_predict_label_L);

