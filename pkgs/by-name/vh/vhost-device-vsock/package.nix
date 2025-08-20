{
  lib,
  fetchFromGitHub,
  rustPlatform,
  nix-update-script,
  testVersion,
  vhost-device-vsock,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "vhost-device-vsock";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "rust-vmm";
    repo = "vhost-device";
    tag = "vhost-device-vsock-v${finalAttrs.version}";
    hash = "sha256-g+u6WBJtizIgQwC0kkWdAcTiYCM1zMI4YBLVRU4MOrs=";
  };

  buildAndTestSubdir = "vhost-device-vsock";

  cargoHash = "sha256-mtORRCY/TNeIEgRCQ1ZbjpsykteRm2FHRveKaQxD/Pw=";

  passthru = {
    updateScript = nix-update-script { };
    tests.version = testVersion { package = vhost-device-vsock; };
  };

  meta = {
    changelog = "https://github.com/uutils/diffutils/releases/tag/vhost-device-vsock-v${finalAttrs.version}";
    description = "device that enables communication between an application running in the guest and an application running on the host";
    homepage = "https://github.com/rust-vmm/vhost-device";
    licenses = [
      lib.licenses.bsd3
      lib.licenses.asl20
    ];
    mainProgram = "vhost-device-vsock";
    maintainers = [ lib.maintainers.YorikSar ];
    platforms = lib.platforms.linux;
  };
})
