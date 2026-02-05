%% ================== 0. 基本信息：12 篇论文 ==================
clear all;  close all;  clc;
paperLabels = { ...
    'Lan 2022', ...        % 2  Drones 2022 Lan 
    'Zhao 2023', ...      % 3  JZJU 工学版 GRU（赵嘉墀 等, 2023）
    'Duan 2024', ...      % 4  Aerospace 2024 BiGRU（Ningyu Duan 等）
    'Pereira 2023', ...   % 5  Eng. Proc. 2023 RNN（João A.F. Pereira 等）
    'Pohly 2021', ...     % 6  Acta Astro. 2021 ANN 模型
    'Hu 2024', ...        % 7  Biomimetics 2024 HCDD-PINN（Fujia Hu 等）
    'Sundar 2025', ...    % 8  JFS 2025 PINN/MB-PINN（Rahul Sundar 等）
    'Cai 2025', ...       % 9  EJM/B Fluids 109 (2025) PINN（Zemin Cai 等）
    'Zhao 2025', ...      % 10 Hybrid PFNN（Zhihao Zhao 等，Journal of Bionic Eng. 2025）
    'Zhao 2023'      % 11 GRU 序列样本数（同 3，强调时间步）
    };      % 12 RNN 序列样本数（同 5，强调时间步）

% 经过验证的参考文献有： 6 

% 对应的神经网络类型（柱子上方要标的）
nnType = { ...
     'ANN', ...          % 2 Drones
    'GRU', ...          % 3 JZJU
    'BiGRU', ...        % 4 Aerospace
    'RNN', ...          % 5 Eng. Proc.
    'ANN', ...          % 6 Acta
    'PINN', ...    % 7 Biomimetics
    'PINN', ...      % 8 JFS
    'PINN', ...         % 9 Cai et al.
    'PFNN', ...         % 10 Hybrid PFNN
    'GRU'   % 11 GRU/时间序列
    };     % 12 RNN/时间序列

%% ================== 1. 训练 / 测试数据量 ==================

N_train = [ ...
    16;            % 2 Energy 2022: 800 中 70% 训练 ≈ 560
    1200;           % 3 JZJU 2023 GRU: 1368 中 1200 组参数组合
    76;             % 4 Aerospace 2024 BiGRU: 84 中约 90% 训练 ≈ 76
    30;             % 5 Eng. Proc. 2023 RNN: 30 训练工况
    100;            % 6 Acta 同 1：100 训练
    1.7e4 + 3.1e5;  % 7 HCDD-PINN: ≈1.7e4 internal + 3.1e5 collocation
    3.186e4*2;      % 8 MB-PINN: N_bulk≈3.186e4 + N_Ph≈3.186e4
    2.0e5 + 2.0e4;  % 9 Cai PINN: 2e5 + 2e4（近似，可按需调）
    0.7*(7000+13000); % 10 PFNN: 两套数据集 70% 训练
    1200*196       % 11 GRU 序列：1200 条 × 196 时间点
    ];          

N_test = [ ...
    9;            % 2 Energy: 20% × 800 = 160 测试算例
    168;            % 3 JZJU GRU: 168 组测试参数组合
    8;              % 4 Aerospace BiGRU: 10% ×84 ≈ 8 组测试样本
    5;              % 5 Eng. Proc. RNN: 5 条验证工况，这里视作测试
    25;             % 6 Acta 同 1：25 测试
    9.7e5;            % 7 HCDD-PINN: 测试主要是和高精度 CFD 对比
    3.255e5;        % 8 MB-PINN: Ref-IBM 高分辨率网格点数
    15;             % 9 Cai PINN: 约 15 组测试帧对
    0.3*(7000+13000); % 10 PFNN: 15%×总样本
    168*196        % 11 GRU 序列：168 条 × 196 时间点
    ];             

% 1=CFD, 2=面板/理论, 3=风洞实验, 4=实飞, 5=混合(解析+CFD+实验)
sourceType = [ ...
    3;  % Lan 2022: CFD
    3;  % Zhao 2023: CFD
    3;  % Duan 2024: CFD (URANS)
    2;  % Pereira 2023: Hess-Smith 面板法
    3;  % Pohly 2021: 3D Navier–Stokes CFD
    3;  % Hu 2024: 粗网格 CFD + PINN（数据本质仍是 CFD）
    3;  % Sundar 2025: IBM/ALE CFD + PINN
    5;  % Cai 2025: 解析 + CFD + 实验速度场
    4;  % Zhao 2025: 实飞数据 + 动力学反算
    3]; % Zhao 2023 (时间步): CFD

% 对于大多数文章，测试/验证数据的来源和训练集相同：
% dataSrcTest = dataSrcTrain;


%% ========== 2. 可调参数区：顺序 / 颜色 / 柱子间隙 ==========

% 2.1 数据顺序（索引）：
% order = (1:10);
% order = [2 3 5 4 1 10 9 8 6 7];
order = [5 1 4 3 2 10 9 8 7 6];
% 1 = ANN（前馈）
% 2 = CNN
% 3 = 时间序列网络（GRU / RNN / BiGRU / PFNN）
% 4 = PINN / MB-PINN

% ==== 1. 基本颜色 ====
trainPalette = [ ...
    0.20 0.45 0.90;  % 1 CFD   训练：亮蓝
    0.93 0.35 0.30;  % 2 Panel 训练：亮红
    0.95 0.60 0.10;  % 3 实验  训练：亮橙（暂未用）
    0.30 0.75 0.30;  % 4 实飞  训练：亮绿
    0.60 0.40 0.80]; % 5 混合  训练：亮紫

testPalette = [ ...
    0.00 0.25 0.60;  % 1 CFD   验证/测试：深蓝
    0.70 0.15 0.15;  % 2 Panel 验证/测试：深红
    0.80 0.45 0.00;  % 3 实验  验证/测试：深橙（预留）
    0.00 0.50 0.00;  % 4 实飞  验证/测试：深绿
    0.42 0.22 0.60]; % 5 混合  验证/测试：深紫

% 按来源类型映射颜色（原始顺序）
trainColors0 = trainPalette(sourceType, :);
testColors0  = testPalette(sourceType,  :);

% 2.4 重排（和 N_train/N_test、标签、网络类型一致）
paperLabels = paperLabels(order);
nnType      = nnType(order);
N_train     = N_train(order);
N_test      = N_test(order);

trainColors = trainColors0(order, :);
testColors  = testColors0(order, :);

% 组装矩阵：每行一个论文，第一列训练，第二列“验证+测试”
Y = [N_train(:), N_test(:)];

%% ========== 3. 作图 ==========
n = size(Y, 1);      % 论文数
xCenter = (1:n)*1.3;       % 每个论文所在的组中心

% ===== 你想控制的两个关键参数 =====
wBar   = 0.3;       % 单个柱子的宽度（0~1 之间，越大越胖）
innerGap = 0.20;     % 组内两根柱子之间的“空隙”大小（单位：x 轴）

% 计算训练 / 测试两根柱子的 x 坐标
xTrain = xCenter - (wBar/2 + innerGap/2);   % 左边一点
xTest  = xCenter + (wBar/2 + innerGap/2);   % 右边一点

figure; hold on; grid on; box on;

% 画训练数据柱子
b1 = bar(xTrain, N_train, wBar);
b1.FaceColor = 'flat';
b1.CData     = trainColors;   % 每根柱子单独上色

% 画验证+测试数据柱子
b2 = bar(xTest,  N_test,  wBar);
b2.FaceColor = 'flat';
b2.CData     = testColors;

% === 去掉柱子边框 ===
b1.EdgeColor = 'none';
b2.EdgeColor = 'none';
b1.FaceAlpha = 0.75;  
b2.FaceAlpha = 0.75;
% 坐标、标签等
set(gca, 'YScale', 'log');
set(gca, 'XTick', xCenter);
set(gca, 'XTickLabel', paperLabels);
xtickangle(0);

ylabel('Data size');
xlabel('Complexity of Neural Networks');
legend({'Training Data','Validation + Test Data'}, ...
       'Location','northoutside','Orientation','horizontal');

leftEdge  = min([xTrain(:); xTest(:)]) - wBar*1.2;  % 左边再放一点点 padding
rightEdge = max([xTrain(:); xTest(:)]) + wBar*1.2;

xlim([leftEdge, rightEdge]);

%% 在每组柱子上方标注神经网络类型（每组标一次），并在每根柱子上标注数值

[ngroups, nbars] = size(Y);    % ngroups = 组数, nbars = 2 (训练/验证)

% 我们不再用 b(j).XEndPoints，而是直接用已知的 xTrain / xTest
% 组内两根柱子的 x 坐标：
xPos = [xTrain(:), xTest(:)];  % ngroups × 2

for i = 1:ngroups
    yi = Y(i, :);
    yi_ok = yi(isfinite(yi) & yi > 0);
    if isempty(yi_ok)
        continue;
    end

    % --- 1) 组的中点：写神经网络类型 ---
    yMax = max(yi_ok);
    xMid = mean(xPos(i, :), 'omitnan');  % 该组两根柱子的中点

    text(xMid, yMax * 1.8, nnType{i}, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment',   'bottom', ...
        'FontSize', 8);

    % --- 2) 每一根柱子：写具体数值 ---
    for j = 1:nbars
        yVal = Y(i, j);
        if ~isfinite(yVal) || yVal <= 0
            continue;   % 跳过 NaN 或 0
        end

        xVal = xPos(i, j);

        % 数值格式：可根据需要改成 '%.1e' 或 '%g'
        labelStr = sprintf('%.3g', yVal);

        % 在该柱子顶部略往上写数值（log 轴下用乘法抬高一点）
        text(xVal, yVal * 1.05, labelStr, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment',   'bottom', ...
            'FontSize', 7);
    end
end


 ylim([1, 1e6*4])
hold off;
