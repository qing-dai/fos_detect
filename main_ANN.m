%% test images

    [filename,pathname] = uigetfile('../images/new/test/*.tif', 'Select image file');
    cfos_test_image_path = [pathname, filename]

    % [filename,pathname] = uigetfile('../images/*.tif', 'Select image file');
    % tdt_test_image_path = [pathname, filename];

    [filename,pathname] = uigetfile('../images/new/test/*.xlsx', 'Select tag file');
    test_tag_path = [pathname, filename]

    [cfos_test_feature_vector, cfos_test_label_vector] = extract_feature_and_import_tags(cfos_test_image_path, test_tag_path, 'cfos');
 



    % [tdt_test_feature_vector, tdt_test_label_vector] = extract_feature_and_import_tags(tdt_test_image_path, test_tag_path, 'tdt');


%%

% [ANN_predict_label] = myNNfun(cfos_test_feature_vector);
[ANN_predict_label] = myNeuralNetworkFunction(cfos_test_feature_vector);


ANN_predict_label(ANN_predict_label < 0.5) = 0;
ANN_predict_label(ANN_predict_label >= 0.5) = 1;

%MYNEURALNETWORKFUNCTION neural network simulation function.
%
% Generated by Neural Network Toolbox function genFunction, 04-Jul-2017 15:23:18.
%
% [y1] = myNNfun(x1) takes these arguments:
%   x = Qx138 matrix, input #1
% and returns:
%   y = Qx1 matrix, output #1
% where Q is the number of samples.


%% accuracy 

tp = 0;
fp = 0;
fn = 0;
tn = 0;


for i = 1:length(ANN_predict_label)
    if (cfos_test_label_vector(i) == 1) && (ANN_predict_label(i) == 1)
        tp = tp + 1;
    elseif (cfos_test_label_vector(i) == 1) && (ANN_predict_label(i) == 0)
        fn = fn + 1;
    elseif (cfos_test_label_vector(i) == 0) && (ANN_predict_label(i) == 1)
        fp = fp + 1    ;
    elseif (cfos_test_label_vector(i) == 0) && (ANN_predict_label(i) == 0)
        tn = tn + 1;
    end 
        
end

precision = tp / (tp + fp);

recall =  tp / (tp + fn);

accuracy = (tp + tn) / (tp + tn + fp + fn );


x = {'ANN', ''; 
    'tp', tp; 'fp', fp; 'fn', fn;
    'precision: ', precision; 'recall: ', recall; 'accuracy: ', accuracy};

display(x);

%% analyze
cfos_mislabel = check_mislabeled(cfos_test_image_path, cfos_test_label_vector, cfos_predict_label);
% % tdt_midlabel = check_mislabeled(tdt_test_image_path, tdt_test_label_vector, tdt_predict_label_L);
