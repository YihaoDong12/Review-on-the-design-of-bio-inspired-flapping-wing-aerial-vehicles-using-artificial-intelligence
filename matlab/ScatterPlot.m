clear; close all; clc;
%% ================== 参数设置 ==================
fileName = 'flapping_wing_dataset_from_scopus.csv';
markerSize = 200; % 散点面积（points^2）
% 颜色：不同 AI 方法
grayColor = [0.5 0.5 0.5]; % AI = 0: 无 AI
redColor = [1 0 0]; % AI = 1: NN
greenColor = [0 1 0]; % AI = 2: GA / 优化
% type 对应的点形状：0=结构机构, 1=运动学, 2=气动, 3=控制
typeMarkers = {'^','s','o','d'};
% AI 风格设置表
aiStyles(1).flag = 0;
aiStyles(1).name = 'No AI';
aiStyles(1).color = grayColor;
aiStyles(1).faceAlpha = 0.3;
aiStyles(1).edgeAlpha = 0.5;
aiStyles(2).flag = 1;
aiStyles(2).name = 'AI (NN)';
aiStyles(2).color = redColor;
aiStyles(2).faceAlpha = 0.9;
aiStyles(2).edgeAlpha = 1.0;
aiStyles(3).flag = 2;
aiStyles(3).name = 'AI (GA)';
aiStyles(3).color = greenColor;
aiStyles(3).faceAlpha = 0.9;
aiStyles(3).edgeAlpha = 1.0;
%% ================== 读取数据 ==================
T = readtable(fileName);
% x = T.wingspan_filled; % m
% y = T.weight_filled; % g
x = T.wingspan; % m
y = T.weight; % g
Type = T.type; % 0~3：结构/运动学/气动/控制
AIflag = T.ai; % 0:无 AI, 1:NN, 2:GA
% tandem 标记
if any(strcmp(T.Properties.VariableNames, 'tandem'))
    tandemFlag = T.tandem;
else
    tandemFlag = zeros(height(T),1); % 没有就全当 0
end
% DataMissed：0 = 正常；1 = 缺失类型1（横线）；2 = 缺失类型2（竖线）
if any(strcmp(T.Properties.VariableNames, 'DataMissed'))
    DataMissed = T.DataMissed;
else
% 兜底逻辑：原始列 <0 当作“缺失类型1”
    DataMissed = zeros(height(T),1);
if all(ismember({'wingspan_m','weight_g'}, T.Properties.VariableNames))
        idx_tmp = (T.wingspan_m < 0) | (T.weight_g < 0);
        DataMissed(idx_tmp) = 1;
end
end
%% ================== 计算坐标轴范围 ==================
xmin = min(x); xmax = max(x);
ymin = min(y); ymax = max(y);
xMargin = 0.05 * (xmax - xmin);
yMargin = 0.05 * (ymax - ymin);
xmin = xmin - xMargin; xmax = xmax + xMargin;
ymin = max(0, ymin - yMargin); % 重量 >= 0
ymax = ymax + yMargin;
xrange = xmax - xmin;
yrange = ymax - ymin;
%% ================== 定义翼展分区 ==================
b_micro_max = 0.15; % 微型上限 (m)
b_small_max = 2.0; % 小型上限 (m)
%% ================== 画图准备 ==================
figure; hold on; box on;

% loglog(x, y, 'ko'); hold on;
plotSizeRegionsLog;

xlabel('Wingspan (m)');
ylabel('Weight (g)');
% title('Flapping-wing UAV Size Regions (log-log)');
grid on;

%% === 形状（type）图例 ===
shapeMarkers = {'^','s','o','d','p'}; % 新增 p 代表 type=4
shapeNames = { ...
'0 = Strucure & Mechanism', ...
'1 = Kinematic', ...
'2 = Aerodynamic', ...
'3 = Conrtol'};
shapeHandles = gobjects(1,5);
for t = 0:4
    shapeHandles(t+1) = plot(nan, nan, ...
'Marker', shapeMarkers{t+1}, ...
'MarkerSize', 9, ...
'LineStyle','none', ...
'MarkerEdgeColor','k', ...
'MarkerFaceColor','none');
end
%% 新增：关系曲线（在散点后绘制，覆盖在上层）
% 生成x范围（log均匀，避开0）
Span = logspace(log10(0.01), log10(2.5), 200);
% 传统曲线 (红色虚线)
m_trad_kg = (Span / 1.17) .^ (1 / 0.39);
y_trad_g = m_trad_kg * 1000;
plot(Span, y_trad_g, '--', ...
    'Color', [1 0.65 0  0.5], ...        % 红色，透明度 0.5（范围 0~1，0=完全透明，1=不透明）
    'LineWidth', 3, ...
    'DisplayName', 'Traditional Scaling: Span = 1.17 m^{0.39}');
% % 改进鸽子曲线 (绿色虚线)
% m_pigeon_kg = (Span / 0.80) .^ (1 / 0.15);
% y_pigeon_g = m_pigeon_kg * 1000;
% plot(Span, y_pigeon_g, 'g--', 'LineWidth', 1.5, 'DisplayName', 'Improved (Pigeon): Span = 0.80 m^{0.15}');
% % 改进鹰类曲线 (蓝色虚线)
% m_eagle_kg = (Span / 1.26) .^ (1 / 0.35);
% y_eagle_g = m_eagle_kg * 1000;
% plot(Span, y_eagle_g, 'b--', 'LineWidth', 1.5, 'DisplayName', 'Improved (Eagle): Span = 1.26 m^{0.35}');

%% 1. tandem = 1：点中心加一层淡灰色圆圈
idx_tandem = (tandemFlag == 1);
% 圆圈大小（points²）：根据视觉效果调节，不随缩放变化
circleSize = markerSize * 2.2;
for i = find(idx_tandem).'
    xc = x(i); yc = y(i);
    scatter(xc, yc, circleSize, ...
'Marker', 'o', ...
'MarkerEdgeColor', [0.6 0.6 0.6], ... % 浅灰色（可改成带透明）
'MarkerFaceColor', 'none', ...
'LineWidth', 1.0, ...
'HandleVisibility', 'off');
end
%% 2. 散点：颜色(AI) + 形状(type)
legendHandles = gobjects(1, numel(aiStyles));
hasLegend = false(1, numel(aiStyles));
for t = 0:3
    marker = typeMarkers{t+1};
    idx_type = (Type == t);
for k = 1:numel(aiStyles)
        idx_grp = idx_type & (AIflag == aiStyles(k).flag);
if ~any(idx_grp), continue; end
% --- 基础散点 ---
        h = scatter(x(idx_grp), y(idx_grp), markerSize, ...
'filled', ...
'Marker', marker, ...
'MarkerFaceColor', aiStyles(k).color, ...
'MarkerFaceAlpha', aiStyles(k).faceAlpha, ...
'MarkerEdgeColor', aiStyles(k).color, ...
'MarkerEdgeAlpha', aiStyles(k).edgeAlpha);
% 只用第一个 handle 进 legend，其余隐藏
if ~hasLegend(k)
            legendHandles(k) = h;
            hasLegend(k) = true;
else
            set(h,'HandleVisibility','off');
end
end
end

%% 3. DataMissed 标记：1=横线, 2=竖线（固定像素大小，不随缩放变化）
hMiss1 = []; % legend 用
hMiss2 = [];

% DataMissed = 1 -> 横线 '_'
    idx_m1 = (DataMissed == 1);
if any(idx_m1)
        h_m1 = plot(x(idx_m1), y(idx_m1), 'k', ...
'LineStyle','none', ...
'Marker','_', ... % R2020b+ 新增 marker
'MarkerSize',10, ...
'LineWidth',1.1, ...
'HandleVisibility','off');
% legend 示例
        hMiss1 = plot(nan, nan, 'k', ...
'LineStyle','none', ...
'Marker','_', ...
'MarkerSize',10, ...
'LineWidth',1.1);
end
% DataMissed = 2 -> 竖线 '|'
    idx_m2 = (DataMissed == 2);
if any(idx_m2)
        h_m2 = plot(x(idx_m2), y(idx_m2), 'color', [0.45 0.45 0.45], ...
'LineStyle','none', ...
'Marker','|', ...
'MarkerSize',10, ...
'LineWidth',1.1, ...
'HandleVisibility','off');
% legend 示例
        hMiss2 = plot(nan, nan, 'color', [0.45 0.45 0.45], ...
'LineStyle','none', ...
'Marker','|', ...
'MarkerSize',10, ...
'LineWidth',1.1);
end
%% 新增：论文中鸟类参考点（黑色五角星，来自Table 1 & 4）
% 数据：翼展 (m), 重量 (g) - 选取典型值（中值或平均）
birdData = [...
    1.44, 1000;  % Buteo lagopus
    0.88, 1012;  % Anas boschas
    0.76, 1000;  % Crax rubra
    0.825, 90;   % Arctic Tern 
    0.90, 400;   % Bar-tailed Godwit
    0.675, 320;  % Homing Pigeon
    0.575, 200;  % Spotted Dove
    1.275, 1100; % Common Raven
    0.925, 450;  % American Crow
    1.00, 900;   % Peregrine Falcon
    2.00, 4750;  % Golden Eagle
    3.00, 7000;  % Wandering Albatross
    2.50, 8000;  % Gyps rueppelli
    0.325, 17.5; % Barn Swallow
    0.35, 50;    % Common Swift
    0.11, 3.5    % Hummingbird
];
scatter(birdData(:,1), birdData(:,2), markerSize/1.5, ...
    'k', 'p', 'filled', ...
    'MarkerFaceAlpha', 0.7, ...
    'DisplayName', 'Birds from Paper');
%% 4. 坐标轴和图例
xlim([0.02, 3.5]);
ylim([0.01, 10000]); % 注意 log 轴不能有 0 → 需设为正数下界
set(gca, 'XScale', 'log'); % X 轴对数
set(gca, 'YScale', 'log'); % Y 轴对数
xlabel('Wingspan (m)');
ylabel('Weight (g)');
grid on;
%% === 在坐标轴上标注区域边界值 ===
xt = get(gca,'XTick'); % 取得原来的 X 轴刻度
% 新的刻度 = 原刻度 + 区域边界
xt_new = unique([xt, b_micro_max, b_small_max]);
set(gca, 'XTick', xt_new);
% 可选：格式化数字（如果你不需要科学计数法）
set(gca, 'XTickLabel', arrayfun(@(v) sprintf('%g', v), xt_new, 'UniformOutput', false));



% % AI 图例（只保留真正出现的）
% maskLegend = hasLegend;
% legendHandles = legendHandles(maskLegend);
% aiNames = {aiStyles(maskLegend).name};
% % DataMissed 图例（只在存在对应点时添加）
% extraHandles = [];
% extraLabels = {};
% if ~isempty(hMiss1) && isgraphics(hMiss1)
%     extraHandles(end+1) = hMiss1;
%     extraLabels{end+1} = 'DataMissed = 1 (horizontal)';
% end
% if ~isempty(hMiss2) && isgraphics(hMiss2)
%     extraHandles(end+1) = hMiss2;
%     extraLabels{end+1} = 'DataMissed = 2 (vertical)';
% end
% allHandles = [legendHandles, extraHandles, shapeHandles];
% allLabels = [aiNames, extraLabels, shapeNames];
% if ~isempty(allHandles)
%     legend('Location','best');
% end
% title('Flapping-wing dataset: wingspan vs. weight');



function h = plotSizeRegionsLog(varargin)
% PLOTSIZEREGIONSLOG 在 log-log 坐标下绘制 微型/小型/大型 扑翼无人机区域
%
% 使用方法：
%   loglog(x, y, 'o'); hold on;
%   plotSizeRegionsLog;   % 自动读取当前坐标轴范围，并绘制区域
%
% 输出：
%   h = [hMicro, hSmall, hLarge] patch 句柄

%% 颜色与透明度
col_micro = [0.7 0.85 1.0];   % 淡蓝
col_small = [0.8 1.0 0.8];    % 淡绿
col_large = [1.0 0.9 0.8];    % 淡橙
alphaVal = 0.2;

%% 三类 UAV 尺度定义（你给的区间）
b_micro = [0.005 0.15];
m_micro = [0.005 15];

b_small = [0.005 2.0];
m_small = [0.005 1000];

b_large = [0.005 1000000];
m_large = [0.005 1000000];

%% 获取当前坐标轴范围（loglog）
ax = gca;
xmin = ax.XLim(1); xmax = 10;
ymin = ax.YLim(1); ymax = 10000;

% 保证区间截断到当前坐标范围内
clip = @(v, lo, hi) min(max(v, lo), hi);

%% 微型区域
bx = [clip(b_micro(1), xmin, xmax), clip(b_micro(2), xmin, xmax)];
by = [clip(m_micro(1), ymin, ymax), clip(m_micro(2), ymin, ymax)];
[Xm,Ym] = meshgrid(bx,by);
hMicro = patch(Xm([1 2 4 3]), Ym([1 2 4 3]), col_micro, ...
    'EdgeColor','none','FaceAlpha',alphaVal);

%% 小型区域
bx = [clip(b_small(1), xmin, xmax), clip(b_small(2), xmin, xmax)];
by = [clip(m_small(1), ymin, ymax), clip(m_small(2), ymin, ymax)];
[Xs,Ys] = meshgrid(bx,by);
hSmall = patch(Xs([1 2 4 3]), Ys([1 2 4 3]), col_small, ...
    'EdgeColor','none','FaceAlpha',alphaVal);

%% 大型区域（右上角无限延伸至坐标轴边界）
bx = [clip(b_large(1), xmin, xmax), xmax];
by = [clip(m_large(1), ymin, ymax), ymax];
[Xl,Yl] = meshgrid(bx,by);
hLarge = patch(Xl([1 2 4 3]), Yl([1 2 4 3]), col_large, ...
    'EdgeColor','none','FaceAlpha',alphaVal);

%% 输出
h = [hMicro, hSmall, hLarge];

end
