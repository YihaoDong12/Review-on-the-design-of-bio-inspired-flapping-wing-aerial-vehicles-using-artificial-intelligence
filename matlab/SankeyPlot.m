function AI_Flapping_Sankey
% AI_Flapping_Sankey
% 矩形桑基图（NN+PHYS 合并，高对比度配色，灰背景，无文字）
% 依赖：slandarer 的 SSankey 工具箱（File Exchange: sankey plot）

clc; clear; close all;

%% 1. 节点（全部用代号）
nodeList = { ...
    'SM','KIN','AERO','CTL','SNS', ...          % 1–5  领域
    'P_SM','P_KIN','P_AE','P_CTL','P_SNS', ...  % 6–10 仿生问题
    'D_LOW','D_CFD','D_EXP', ...                % 11–13 数据
    'NN','EVO','RL','BO', ...                   % 14–17 AI 方法（NN+PHYS 合并）
    'G_PERF','G_PWR','G_AERO','G_CTL','G_SNS'}; % 18–22 性能指标

N      = numel(nodeList);
AdjMat = zeros(N);

%% 2. 流向权重

% ===== 0. 初始化 =====
N = 23;
AdjMat = zeros(N);

% ===== 1. 领域 -> 问题 =====
% 1: Structures / Mechanisms
% 2: Kinematics
% 3: Aerodynamics
% 4: Control
% 5: Sensing
AdjMat(1,6)  = 8;   % SM   -> P_struct
AdjMat(1,7)  = 2;   % SM   -> P_kin   (结构参与到步态/运动共设计的那一小部分)

AdjMat(2,7)  = 10;  % KIN  -> P_kin
AdjMat(2,8)  = 2;   % KIN  -> P_aero  (运动优化里顺带做气动代理的几篇)

AdjMat(3,8)  = 9;   % AERO -> P_aero

AdjMat(4,9)  = 11;  % CTL  -> P_ctrl
AdjMat(4,8)  = 2;   % CTL  -> P_aero  (控制里做气动建模/代理的几篇)

AdjMat(5,10) = 7;   % SNS  -> P_sense

% 由此得到各问题节点目标流量：
% P_struct=8, P_kin=12, P_aero=13, P_ctrl=11, P_sense=7

% ===== 2. 问题 -> 数据 =====
% 6: P_struct: Structure & morphing design
AdjMat(6,11) = 4;   % -> Low‑order (MBD/FE/简化模型)
AdjMat(6,12) = 3;   % -> High‑order CFD（如 Han 等 [37] 这类带 CFD 的）:contentReference[oaicite:0]{index=0}
AdjMat(6,13) = 1;   % -> Experiments & images（GAN+翼图像、结构测试等）:contentReference[oaicite:1]{index=1}
% 出流 4+3+1 = 8，与进入 8 平衡

% 7: P_kin: Kinematic & gait optimization
% 重新把 Bender GPDM、Gehrke PIV、Yang 图像形态等算进实验数据这一类:contentReference[oaicite:2]{index=2}
AdjMat(7,11) = 7;   % -> Low‑order (MBD/QSM/UVLM/简化 FSI 等)
AdjMat(7,12) = 3;   % -> CFD/DNS 代理驱动的优化
AdjMat(7,13) = 2;   % -> 纯实验/形态数据驱动的运动/关节优化（GPDM、PIV、图像等）
% 出流 7+3+2 = 12，与进入 12 平衡

% 8: P_aero: Aero surrogate & flow prediction
% 这里新增一部分基于面元法/QSM 等的“低阶气动数据”
AdjMat(8,11) = 2;   % -> Low‑order (HSPM/QSM 类低阶):contentReference[oaicite:3]{index=3}
AdjMat(8,12) = 8;   % -> CFD/DNS 训练的 NN/GRU/CNN/PINN 等:contentReference[oaicite:4]{index=4}
AdjMat(8,13) = 3;   % -> 风洞、飞行日志等真实数据
% 出流 2+8+3 = 13，与进入 13 平衡

% 9: P_ctrl: Stabilization & maneuvers
AdjMat(9,11) = 4;   % -> 低阶动力学模型 + 控制
AdjMat(9,13) = 7;   % -> 实飞/试验数据驱动控制
% 出流 11 平衡

% 10: P_sense: Perception & flow reconstruction
AdjMat(10,13) = 7;  % -> 传感器与飞行日志（应变、视觉、IMU 等）:contentReference[oaicite:5]{index=5}
% 出流 7 平衡

% 此时五个问题节点总出流 = 8+12+13+11+7 = 51

% ===== 3. 数据 -> AI 方法 =====
% 11: D_low  17 单元 (结构/机制 + 运动 + 控制中的低阶模型)
AdjMat(11,14) = 6;  % -> NN  (ANN/RNN/PFNN 等基于低阶模型训练的):contentReference[oaicite:6]{index=6}
AdjMat(11,15) = 8;  % -> Evo (GA/ES/PSO；大量结构/运动共设计使用):contentReference[oaicite:7]{index=7}
AdjMat(11,16) = 3;  % -> RL/IL (在简化仿真环境中训练的策略)
% 出流 6+8+3 = 17，与 4+7+2+4 = 17 平衡

% 12: D_cfd  14 单元 (高保真 CFD/DNS)
AdjMat(12,14) = 10;  % -> NN (CFD‑驱动代理/RNN/GRU/CNN/PINN 等)
AdjMat(12,15) = 3;  % -> Evo (CFD-in-the-loop GA/ES)
AdjMat(12,17) = 1;  % -> BO (多保真 GP‑BO 串 CFD/实验):contentReference[oaicite:9]{index=9}
% 出流 7+3+3+1 = 14，与 3+3+8 = 14 平衡

% 13: D_real  20 单元 (风洞/飞行日志/应变/视觉等实际实验数据)
AdjMat(13,14) = 12; % -> NN (飞行日志 PFNN、CNN 视觉、振动感知 NN 等)
AdjMat(13,16) = 8;  % -> RL/IL (试验/仿真混合训练控制与感知):contentReference[oaicite:10]{index=10}
% 出流 10+2+8 = 20，与 1+2+3+7+7 = 20 平衡

% ===== 4. AI 方法 -> 性能指标 =====
% 14: M_NN  (总入流 23 = 6+7+10)
AdjMat(14,18) = 5;  % -> G_perf: 升力/推力/载荷提升
AdjMat(14,19) = 5;  % -> G_power: 功率/效率
AdjMat(14,20) = 9;  % -> G_aeroPred: 气动预测精度/速度
AdjMat(14,21) = 7;  % -> G_ctrl: 稳定与跟踪
AdjMat(14,22) = 2;  % -> G_sense: 感知/鲁棒性


% 16: M_Evo  (GA/ES/PSO，入流 11 = 8+3)
AdjMat(15,18) = 6;  % -> 性能（升力/推力/载荷）
AdjMat(15,19) = 5;  % -> 功率/效率
% 出流 11 平衡

% 17: M_RL  (RL/IL，入流 11 = 3+8)
AdjMat(16,21) = 7;  % -> 控制/机动性
AdjMat(16,18) = 2;  % -> 性能（比如极限机动）
AdjMat(16,22) = 2;  % -> 感知/鲁棒性提升
% 出流 7+2+2 = 11 平衡

% 18: M_BO  (GP-BO，入流 1)
AdjMat(17,20) = 1;  % -> 气动预测/优化（昂贵目标下的采样效率）
% 出流 1 平衡


%% 3. 创建 SSankey 对象
SK = SSankey([], [], [], 'NodeList', nodeList, 'AdjMat', AdjMat);

% 层信息：1–5 领域；6–10 问题；11–13 数据；14–17 方法；18–22 性能
SK.Layer = [ ...
    1 1 1 1 1, ...
    2 2 2 2 2, ...
    3 3 3, ...
    4 4 4 4, ...
    5 5 5 5 5];

%% 4. 配色：高对比度（不做整体提亮）

white = [1 1 1];

% ---- 领域层（更饱和）----
cSM   = [246 189  96]/255;   % 暖橙黄
cKIN  = [226 115 122]/255;   % 饱和粉红
cAERO = [125 190 214]/255;   % 亮青蓝
cCTL  = [ 54  93 169]/255;   % 深蓝
cSNS  = [183 151 214]/255;   % 紫色

% ---- 仿生问题层（同色系浅一档）----
cSM_P   = 0.60*cSM   + 0.40*white;
cKIN_P  = 0.60*cKIN  + 0.40*white;
cAERO_P = 0.60*cAERO + 0.40*white;
cCTL_P  = 0.60*cCTL  + 0.40*white;
cSNS_P  = 0.60*cSNS  + 0.40*white;

% ---- 数据层：中性浅灰/浅蓝 ----
cLOW = [233 229 220]/255;
cCFD = [210 222 235]/255;
cEXP = [238 228 205]/255;


% AI 方法层：柔和莫兰迪、偏亮
cNN   = [193 210 238]/255;
cEVO  = [249 226 174]/255;
cRL   = [196 222 222]/255;
cBO   = [239 196 190]/255;

% ---- 性能层：略深，增强对比 ----
cG_PERF = [239 189 120]/255;
cG_PWR  = [137 191 203]/255;
cG_AERO = [215 144 157]/255;
cG_CTL  = [ 75 120 170]/255;
cG_SNS  = [166 139 193]/255;

% 写入 ColorList（顺序必须与 nodeList 一致）
SK.ColorList = [ ...
    cSM; cKIN; cAERO; cCTL; cSNS; ...
    cSM_P; cKIN_P; cAERO_P; cCTL_P; cSNS_P; ...
    cLOW; cCFD; cEXP; ...
    cNN; cEVO; cRL; cBO; ...
    cG_PERF; cG_PWR; cG_AERO; cG_CTL; cG_SNS];

% 整体再稍微提亮一点（可以调大/调小）
brightFactor = 0.12;
SK.ColorList = SK.ColorList*(1-brightFactor) + ...
               brightFactor*ones(size(SK.ColorList));


%% 5. 风格：窄 block + 渐变连线 + 灰背景

bgColor = [0.94 0.94 0.94];      % 浅灰背景

fig = figure('Color', bgColor, ...
             'Units','normalized', ...
             'Position',[0.05 0.1 0.9 0.75]);

SK.BlockScale         = 0.05;
SK.Sep                = 0.12;
SK.Align              = 'center';
SK.RenderingMethod    = 'interp';   % 连线颜色 = 两端节点渐变
SK.LabelLocation      = 'right';    % 先画，后删
% SK.ValueLabelLocation = 'none';     % 不显示数值文字

SK.draw();

ax = gca;
set(ax,'Color', bgColor);
axis(ax,'off');
% 
% %% 把所有节点文字关掉（节点标签）
nNode = numel(SK.NodeList);
for i = 1:nNode
    % 方式 1：直接把文本设成空
    SK.setLabel(i,'String','');
    % 方式 2（一般也支持）：隐藏可见性
    % SK.setLabel(i,'Visible','off');
end

% %% 6. 删除所有文字（如果想看文字，把这一段注释掉）
% delete(findall(gcf,'Type','text'));
% delete(findall(gcf,'Type','textboxshape'));

%% 7. block 边框
nBlock = numel(SK.NodeList);
for k = 1:nBlock
    SK.setBlock(k, ...
        'EdgeColor',[0.6 0.6 0.6], ...
        'LineWidth',0.8);
end

%% 8. 连线透明度
nLink = nnz(AdjMat);           % 非零元素个数 ≈ 连线数
for k = 1:nLink
    SK.setLink(k, ...
        'FaceAlpha',0.70, ...
        'EdgeAlpha',0.70);
end

end
