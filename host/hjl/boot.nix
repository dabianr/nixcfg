{ config, pkgs, ... }:{
	boot = {
		# kernelPackages = pkgs.stable.linuxPackages_zen;
		# kernelPackages = pkgs.linuxKernel.packages.linux_zen;
		kernelPackages = pkgs.linuxKernel.packages.linux_xanmod;
		supportedFilesystems = [ "ntfs" ];
		kernel.sysctl = {
		};
		kernelParams=[
		];

		loader = {
			systemd-boot.enable = true;
			efi = {
				canTouchEfiVariables = true;
				efiSysMountPoint = "/boot";
			};
			# grub = {
			# 	efiSupport = true;
			# 	#efiInstallAsRemovable = true; # 如果 canTouchEfiVariables不能用
			# 	device = "nodev";
			# };
		};
	};
}