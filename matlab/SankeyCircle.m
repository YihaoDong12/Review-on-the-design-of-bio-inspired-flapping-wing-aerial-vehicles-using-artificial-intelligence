%% Circle Sankey with "figure style" colours
clear; close all; clc;

%% 1. 节点顺序：先 5 个领域，再 3 个方法
NameList = { ...
    'Control', ...               % 1
    'Aerodynamics', ...          % 2
    'Kinematics', ...            % 3
    'Structure', ...             % 4
    'Sensors', ...               % 5
    'Neural network', ...        % 6
    'Reinforcement learning', ...% 7
    'Genetic algorithms'};       % 8

nNode   = numel(NameList);
dataMat = zeros(nNode);          % 邻接矩阵：行->列 表示箭头方向

iCtrl = 1; iAero = 2; iKin = 3; iStr = 4; iSens = 5;
iNN   = 6; iRL   = 7; iGA  = 8;

%% 领域 -> 方法 的统计数据（按 Table 2–8 重新汇总）

% Control 域：大量 NN 控制器 + 若干 RL 和 GA 优化控制律
dataMat(iCtrl,iNN) = 27;
dataMat(iCtrl,iRL) = 9;
dataMat(iCtrl,iGA) = 3;

% Aerodynamics 域：以 NN 代理模型为主，少量 RL/GA 优化
dataMat(iAero,iNN) = 20;
dataMat(iAero,iRL) = 3;
dataMat(iAero,iGA) = 2;

% Kinematics 域：GA 为主，NN 代理 + 少量 RL 运动合成
dataMat(iKin,iNN)  = 11;
dataMat(iKin,iRL)  = 1;
dataMat(iKin,iGA)  = 20;

% Structure & Mechanism 域：NN 结构代理 + GA 拓扑 / 机构优化
dataMat(iStr,iNN)  = 6;
dataMat(iStr,iRL)  = 0;
dataMat(iStr,iGA)  = 6;

% Sensors / Perception 域：多为 NN 融合，少量 RL 感知–动作闭环
dataMat(iSens,iNN) = 6;
dataMat(iSens,iRL) = 1;
dataMat(iSens,iGA) = 0;


%% 3. 外圈扇区颜色（参考示例图的风格）

% 5 个领域（上半圈）——饱和一点
% cCtrl = [ 146  187 167]/255*1.2;  % 深蓝
% cAero = [238 193 110]/255; % 金黄
% cKin  = [ 63  77  99]/255*1.5; % 深灰蓝
% cStr  = [236 179 164]/255; % 柔粉
% cSens = [230 136  32]/255; % 橙黄


cStr   = [246 189  96]/255;   % 暖橙黄
cKin  = [226 115 122]/255;   % 饱和粉红
cAero = [125 190 214]/255;   % 亮青蓝
cCtrl  = [ 54  93 169]/255;   % 深蓝
cSens  = [183 151 214]/255;   % 紫色

% 3 个方法（下半圈）——同一色系的偏淡莫兰迪色
% cNN   = [189 205 232]/255; % 浅蓝
% cRL   = [245 221 170]/255; % 浅黄
% cGA   = [214 200 211]/255; % 浅粉灰

cNN   = [193 210 238]/255;
cGA  = [249 226 174]/255;
cRL   = [196 222 222]/255;
cBO   = [239 196 190]/255;

CList = [cCtrl; cAero; cKin; cStr; cSens; cNN; cRL; cGA];

%% 4. 画圆形桑基图，箭头从「领域」指向「方法」
figure('Color','w','Units','normalized','Position',[0.1 0.1 0.7 0.75]);

BCC = biChordChart(dataMat, ...
    'Label',   NameList, ...
    'Arrow',   'on', ...
    'Sep',     1/30, ...     % 扇区间隙
    'CData',   CList, ...
    'LRadius', 1.35);        % 标签半径

BCC = BCC.draw();
axis equal off;

% 只保留刻度线，不要刻度值
BCC.tickState('on');        % 有刻度线
BCC.tickLabelState('on');  % 关闭刻度数字

% % 外圈只保留刻度线，不显示刻度数字
% BCC.tickState('on');          % 有刻度线
% if ismethod(BCC,'tickLabelState')
%     BCC.tickLabelState('on');   % 刻度值关掉
% end

%% 5. 每条弦用不同颜色 + 半透明（模仿示例图那样的柔和色带）

[rowIdx, colIdx] = find(dataMat > 0);
nLink            = numel(rowIdx);

% 自定义一个柔和的配色表（8 种，够用就循环）
% 自定义一个柔和的配色表（8 种，蓝色占比更少）
linkCmap = [ ...
    249 225 166;  % 浅米黄（暖）
    245 204 177;  % 肉粉橙（暖）
    232 190 187;  % 柔和红粉（暖）
    224 195 206;  % 淡粉紫（暖偏中性）
    214 225 194;  % 浅豆绿（中性偏暖）
    220 220 220;  % 浅灰（中性）
    197 201 233;  % 少量淡紫蓝（冷色，只保留一条偏蓝）
    190 213 215]; % 少量淡青蓝（冷色）

linkCmap = linkCmap/255;


for k = 1:nLink
    i   = rowIdx(k);
    j   = colIdx(k);
    col = linkCmap(mod(k-1,size(linkCmap,1))+1,:); % 每条线一个颜色

    BCC.setChordMN(i,j, ...
        'FaceColor', col, ...
        'FaceAlpha', 0.65);
end

% %% 6. 在箭头附近标数字（如果不需要，整段注释掉）
% theta  = BCC.meanThetaSet;   % 每个扇区中心角
% rLabel = 0.80;               % 数字半径
% 
% for k = 1:nLink
%     i = rowIdx(k);
%     j = colIdx(k);
%     v = dataMat(i,j);
% 
%     ang = 0.3*theta(i) + 0.7*theta(j);  % 靠近目标端（方法）
%     x   = rLabel * cos(ang);
%     y   = rLabel * sin(ang);
% 
%     text(x, y, num2str(v), ...
%         'HorizontalAlignment','center', ...
%         'VerticalAlignment','middle', ...
%         'FontName','Times New Roman', ...
%         'FontSize',9, ...
%         'Color',[0.25 0.25 0.25]);   % 深灰就好
% end

title('AI methods vs. research domains (circular Sankey)', ...
      'FontName','Times New Roman','FontSize',14);
