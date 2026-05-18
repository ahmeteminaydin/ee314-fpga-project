Projeyi gereksinimlere gore modullere bolup tam FPGA akisini kurdum: oyun FSM’i + carpisma/hit tespiti + VGA render + 7‑seg/LED cikislari. Kodlari tekrar taradim ve VS Code hata kontrolunde bir derleme hatasi gorunmedi.

Olusturulan dosyalar ve amaclari:

fpga_top.v: tum modulleri birlestiren top‑level, pin eslesmeleri, debug secimleri
game_logic.v: menu/countdown/gameplay/gameover FSM’leri, oyuncu durumlari, hit/block/guard, round yonetimi
renderer.v: VGA piksel uretimi (arka plan, karakterler, hitbox/hurtbox, HUD)
vga_controller.v: 640x480@60 VGA zamanlamasi
clock_gen.v: 25 MHz pixel clock + 60 Hz game tick + 1 Hz blink
debounce.v: buton debouncing
edge_detect.v: tek‑vurusta edge pulse
seg7_display.v: 7‑segment karakter encoder
game_params.vh: tum ortak sabitler (boyutlar, frame sayilari, hizlar)
Kontroller ve debug:

SW[0] reset, SW[1] debug clock secimi (60 Hz vs manuel), SW[2] hitbox overlay
KEY[0] manuel tick (SW[1]=1 iken)
KEY[3:1] P1 (sol, sag, attack)
GPIO_0[2:0] P2 (sol, sag, attack) — gerekirse polariteyi fpga_top.v icinde tersleyin
Oyun davranisi notlari:

Basic: startup/active/recovery frame’leri tabloda verilenlerle ayni
Special: iki yontem destekli (recovery’de cancel ve “hold+release” ile charge)
Block: geri yurume ile; block point sifirsa guard break
Hitbox recovery’de hurtbox’a donusuyor, debug overlay ile gorulebilir
Isterseniz siradaki adimlar:

Quartus’ta pin assignment yapip fpga_top.v ve diger .v/.vh dosyalarini ekleyin
Kart uzerinde SW/KEY/GPIO tus polarisini test edip gerekirse tersleyin