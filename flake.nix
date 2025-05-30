{
  description = "llonebot.nix";
  outputs = {
    self, nixpkgs, flake-utils,
  }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
    
    # 直接定义默认包
    defaultConfig = {
      vncport = 7081;
      vncpassword = "vncpassword";
      display = ":666";
      novncport = 5900;
    };
    
  in rec {
    devShells.default = pkgs.mkShell {};
    
    lib.buildLLOneBot = config: pkgs.callPackage ./package { inherit config; };

    packages = {
      # 默认包使用默认配置
      default = pkgs.writeScriptBin "LLOneBot" ''
        #!${pkgs.runtimeShell}
        mkdir -p ./LiteLoader /tmp ./data
        if [ -z "$VNC_PASSWD" ]; then
          VNC_PASSWD=${defaultConfig.vncpassword}
        fi
        ${pkgs.bubblewrap}/bin/bwrap \
          --unshare-all \
          --share-net \
          --as-pid-1 \
          --uid 0 --gid 0 \
          --setenv VNC_PASSWD $VNC_PASSWD \
          --ro-bind /nix/store /nix/store \
          --ro-bind ${pkgs.tzdata}/share/zoneinfo/Asia/Shanghai /etc/localtime \
          --bind ./LiteLoader /LiteLoader/ \
          --bind ./data /root/ \
          --proc /proc \
          --dev /dev \
          --tmpfs /tmp \
          ${(lib.buildLLOneBot defaultConfig).script}/bin/LLOneBot
      '';
      
      # 添加 Docker 镜像构建
      dockerImage = pkgs.dockerTools.buildImage {
        name = "llonebot";
        tag = "latest";
        copyToRoot = pkgs.buildEnv {
          name = "llonebot-env";
          paths = [ packages.default pkgs.coreutils pkgs.bash];
        };
        config = {
          Cmd = [ "/bin/LLOneBot" ]; # 根据实际可执行文件路径调整
          Expose = [ "7081" ]; # 曝露端口
        };
      };
    };
  });
}