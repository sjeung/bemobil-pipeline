function EEG_mocap_out = bemobil_mocap_quat2eul(EEG_mocap_in)
% Transforms Quaternion angle values (4 dimensions) into Euler angles (3 dimensions) to make them human-interpretable.
% Quat values will be taken out, and Euler angles will be assigned as new channels
%
% Input arguments:
%       EEG dataset containing mocap channels with quaternion data (must have exactly 4 channels with labels
%       containing "quat_x/y/z/w")
%
% Output argument:
%       EEG dataset containing mocap channels with euler data (will have no quaternion channels but instead
%       euler angle channels with the replaced names of "euler_x/y/z")
%
% Usage:


for channel = 1:EEG_mocap_in.nbchan
    
    % checking for already present eulers
    if any(~cellfun(@isempty,strfind(lower({EEG_mocap_in.chanlocs.labels}),'eul')))
        error('Dataset already contains Euler data.')
    end
    
end

assert(EEG_mocap_in.nbchan == 7,'Rigidbody quaternion dataset needs to have exactly 7 channels: XYZ position and XYZW quaternions.')
% no eulers are present, therefore each RB has 7 channels:
% XYZABCD, from which ABCD are the quaternion values

data = EEG_mocap_in.data';
newData = zeros(size(data,1),6);
newLabel = cell(6,1);
% the new Euler data has 1 channel less than the quaternions

% fill the new data set and its label with all initial position data
channel_labels = {EEG_mocap_in.chanlocs.labels};
non_quat_indices = cellfun(@isempty,strfind(lower(channel_labels),'quat'));

newLabel(1:sum(non_quat_indices)) = channel_labels(non_quat_indices);
newData(:,1:sum(non_quat_indices)) = data(:,non_quat_indices);

% now fill with euler data
quat_indices = ~cellfun(@isempty,strfind(lower(channel_labels),'quat'));
assert(sum(quat_indices)==4,'There must be exactly 4 quaternion channels containing the label ''quat_<x,y,z,w>''!')


% find correct channelnumber for the quaternion values of
% this RB
quaternionX = ~cellfun(@isempty,strfind(lower(channel_labels),'quat_x'));
assert(sum(quaternionX)==1,'There must be exactly 1 quaternion channel containing the label ''quat_x''!')
quaternionY = ~cellfun(@isempty,strfind(lower(channel_labels),'quat_y'));
assert(sum(quaternionY)==1,'There must be exactly 1 quaternion channel containing the label ''quat_y''!')
quaternionZ = ~cellfun(@isempty,strfind(lower(channel_labels),'quat_z'));
assert(sum(quaternionZ)==1,'There must be exactly 1 quaternion channel containing the label ''quat_z''!')
quaternionW = ~cellfun(@isempty,strfind(lower(channel_labels),'quat_w'));
assert(sum(quaternionW)==1,'There must be exactly 1 quaternion channel containing the label ''quat_w''!')

% take the values
x = data(:,quaternionX);
y = data(:,quaternionY);
z = data(:,quaternionZ);
w = data(:,quaternionW);


% check if values are [-1 1] - could have been messed up by
% interpolating or filtering, would be undefined then.
w(w>=1) = 0.99999;
w(w<=-1) = -0.99999;
x(x>=1) = 0.99999;
x(x<=-1) = -0.99999;
y(y>=1) = 0.99999;
y(y<=-1) = -0.99999;
z(z>=1) = 0.99999;
z(z<=-1) = -0.99999;

% transform to ZYX sequence euler angles
disp('Transforming Quaternions to Euler angles using a Body-ZYX sequence!')
eulers = util_quat2eul([w x y z]');

% selfmade formula
%             eulerX = atan2(2.*(w.*x + y.*z),1 - 2.*(x.^2 + y.^2));     % wikipedia roll (rotation about x)
%             eulerY = asin(2.*(w.*y - z.*x));                             % wikipedia pitch (rotation about y)
%             eulerZ = atan2(2.*(w.*z + x.*y),1-2.*(y.^2+z.^2));          % wikipedia yaw (rotation about z)
%
% eulers(1,:) = eulerX;
% eulers(2,:) = eulerY;
% eulers(3,:) = eulerZ;

% convert from radian to degree
eulers = eulers'*180/pi;

% fill new data set and labels
newData(:,4:6) = eulers;

% take the original prefix before 'quat_x' as a prefix for all new euler channels
newLabel{4} = strcat(channel_labels{4}(1:strfind(lower(channel_labels{4}),'quat_x')-1),'euler_x');
newLabel{5} = strcat(channel_labels{4}(1:strfind(lower(channel_labels{4}),'quat_x')-1),'euler_y');
newLabel{6} = strcat(channel_labels{4}(1:strfind(lower(channel_labels{4}),'quat_x')-1),'euler_z');

% make new set
EEG_mocap_out = EEG_mocap_in;
EEG_mocap_out.nbchan = 6;
EEG_mocap_out.data = newData';
EEG_mocap_out.chanlocs(end) = [];
EEG_mocap_out.chanlocs(4).labels = newLabel{4};
EEG_mocap_out.chanlocs(5).labels = newLabel{5};
EEG_mocap_out.chanlocs(6).labels = newLabel{6};

EEG_mocap_out.etc.quat2eul_sequence = 'Body-ZYX';