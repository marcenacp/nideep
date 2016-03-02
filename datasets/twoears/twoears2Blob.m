function [x_feat, feature_type_names, y, y_1hot] = twoears2Blob(x, featureNames, y)
% twoears2Blob  reshape feature and ground truth vectors into 4-D Blob for caffe
%   For the feature vector x it expects a shape of (N x D)
%   where N is the number of samples and D is the total no. of features
%
%   For the ground truth vectors y it expects a shape of (N x K)
%   where N is the number of samples and K is the number of classes.
%   The ground truth vectors can be one-hot or multi-label vectors
%
%   See also twoears2hdf5.

x = x';
y = y';

% assume first field contains feature name
feature_type_names = unique(cellfun(@(v) v(1), featureNames(1,:)));
x_feat = cell(size(feature_type_names));
for ii = 1 : numel(feature_type_names)
    disp(feature_type_names{ii})
    
    is_feat = cellfun(@(v) strfind([v{:}], feature_type_names{ii}), ...
        featureNames, 'un', false);
    feat_idxs = find(not(cellfun('isempty', is_feat)));
    
    t_idxs_names = unique(cellfun(@(v) v(4), featureNames(feat_idxs)));
    t_idxs = sort( cell2mat( cellfun(@(x) str2double(char(x(2:end))), t_idxs_names, 'un', false) ) );
    
    num_blocks = length( t_idxs );
    
    disp(min(t_idxs))
    disp(max(t_idxs))
    
    if strcmp(feature_type_names{ii}, 'amsFeatures')
        % T x F x mF x N
        % get indicies of features with modulation frequencies
        is_feat_with_mf = cellfun(@(v) strfind([v{:}], 'mf'), featureNames, 'un', false);
        mf_idxs = find(not(cellfun('isempty', is_feat_with_mf)));
        % assume no. of freq. channels are kept constant throughout feat.
        num_freqChannels = str2double( char( strrep( featureNames{ feat_idxs(1) }( 2 ), '-ch', '' ) ) );
        assert( isequal(mf_idxs, feat_idxs), ...
            'Unexpected format for amsFeatures, subset without modulation frequencies');
        % get index of modulation frequencies in ams feature vector
        % assume the index is fixed for all ams features
        tmp = cellfun(@(v) strfind(v, 'mf'), featureNames{ feat_idxs(1) }, ...
            'un', false);
        mf_idx = find( not(cellfun('isempty', tmp)) ); % e.g. 8
        mf_idxs_names = unique( cellfun(@(v) v(mf_idx), featureNames(1, feat_idxs)) );
        num_mod_freq = length( cell2mat( cellfun(@(x) str2double(char(x(3:end))), ...
            mf_idxs_names, 'un', false) ) );
        % first t, then f, then mf
    elseif strcmp(feature_type_names{ii}, 'ratemap')
        %  T x F x 1 x N
        num_freqChannels = str2double( char( strrep( featureNames{1}( 2 ), '-ch', '' ) ) );
        num_mod_freq = 1;
    else
        error('feature %s type not supported', feature_type_names{ii});
    end
    x_feat_tmp = x(feat_idxs, :);
    x_feat_tmp = reshape( x_feat_tmp, num_blocks, num_freqChannels, num_mod_freq, length( x_feat_tmp ) );
    x_feat{ii} = x_feat_tmp;
end % format features

% reshape multi-label ground truth vectors to 4-D Blob
y = reshape( y, 1, [], 1, length( y ) );

% labels in one-hot format for softmax loss
y_1hot = reshape(y, [], length(y));
[class_ids, sample_idx] = find(y_1hot==1);
y_1hot = zeros(1, length(y_1hot));
y_1hot(:, sample_idx) = class_ids;
y_1hot = y_1hot-1; % 1-based to zero-based class index
% to 4-D Blob
y_1hot = reshape(y_1hot, 1, 1, 1, length(y));

