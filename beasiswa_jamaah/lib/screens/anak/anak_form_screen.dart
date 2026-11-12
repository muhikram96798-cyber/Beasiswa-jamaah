// Layar: Form Tambah / Ubah Data Anak Penerima Beasiswa
// Dilengkapi dengan kalkulasi real-time nama samaran, skor seleksi,
// dan estimasi kebutuhan dana bersih program.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/anak.dart';
import '../../providers/anak_provider.dart';
import '../../providers/pengaturan_provider.dart';
import '../../utils/inisial_helper.dart';
import '../../utils/rupiah_formatter.dart';
import '../../utils/skor_seleksi.dart';

class AnakFormScreen extends StatefulWidget {
  final Anak? anak;

  const AnakFormScreen({super.key, this.anak});

  @override
  State<AnakFormScreen> createState() => _AnakFormScreenState();
}

class _AnakFormScreenState extends State<AnakFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaLengkapController;
  late TextEditingController _namaSamaranController;
  late TextEditingController _jumlahSaudaraController;
  late TextEditingController _namaWaliController;
  late TextEditingController _keteranganController;

  late Jenjang _jenjang;
  late int _kelas;
  late StatusYatim _statusYatim;
  late KondisiEkonomi _kondisiEkonomi;
  late StatusPip _statusPip;
  late bool _buruhTani;
  late bool _aktif;
  late DateTime _tanggalMasuk;

  String? _kodeAnak;
  bool _sedangMenyimpan = false;

  bool get _isEdit => widget.anak != null;

  @override
  void initState() {
    super.initState();
    final a = widget.anak;
    _namaLengkapController = TextEditingController(text: a?.namaLengkap ?? '');
    _namaSamaranController = TextEditingController(text: a?.namaSamaran ?? '');
    _jumlahSaudaraController =
        TextEditingController(text: (a?.jumlahSaudara ?? 2).toString());
    _namaWaliController = TextEditingController(text: a?.namaWali ?? '');
    _keteranganController = TextEditingController(text: a?.keterangan ?? '');

    _jenjang = a?.jenjang ?? Jenjang.sd;
    _kelas = a?.kelas ?? 1;
    _statusYatim = a?.statusYatim ?? StatusYatim.yatim;
    _kondisiEkonomi = a?.kondisiEkonomi ?? KondisiEkonomi.sangatKurang;
    _statusPip = a?.statusPip ?? StatusPip.belum;
    _buruhTani = a?.buruhTani ?? false;
    _aktif = a?.aktif ?? true;
    _tanggalMasuk = a != null
        ? (DateTime.tryParse(a.tanggalMasuk) ?? DateTime.now())
        : DateTime.now();
    _kodeAnak = a?.kodeAnak;

    if (!_isEdit) {
      _ambilKodeBaru();
    }
  }

  Future<void> _ambilKodeBaru() async {
    final kode = await context.read<AnakProvider>().getKodeBaru();
    if (mounted) setState(() => _kodeAnak = kode);
  }

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _namaSamaranController.dispose();
    _jumlahSaudaraController.dispose();
    _namaWaliController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _updateNamaSamaranOtomatis() {
    final nama = _namaLengkapController.text.trim();
    if (nama.isNotEmpty) {
      final samaran = buatNamaSamaran(
        namaLengkap: nama,
        jenjang: _jenjang,
        kelas: _kelas,
      );
      _namaSamaranController.text = samaran;
    }
  }

  List<int> _daftarKelasUntukJenjang(Jenjang j) {
    switch (j) {
      case Jenjang.sd:
        return [1, 2, 3, 4, 5, 6];
      case Jenjang.smp:
        return [7, 8, 9];
      case Jenjang.sma:
        return [10, 11, 12];
    }
  }

  Future<void> _pilihTanggalMasuk() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalMasuk,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() => _tanggalMasuk = picked);
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final namaLengkap = _namaLengkapController.text.trim();
    String namaSamaran = _namaSamaranController.text.trim();
    if (namaSamaran.isEmpty) {
      namaSamaran = buatNamaSamaran(
        namaLengkap: namaLengkap,
        jenjang: _jenjang,
        kelas: _kelas,
      );
    }

    final jumlahSaudara = int.tryParse(_jumlahSaudaraController.text) ?? 0;
    final tanggalStr = DateFormat('yyyy-MM-dd').format(_tanggalMasuk);
    final kode = _kodeAnak ?? 'A-01';

    setState(() => _sedangMenyimpan = true);

    try {
      final anakProvider = context.read<AnakProvider>();

      if (_isEdit) {
        final updated = widget.anak!.copyWith(
          namaLengkap: namaLengkap,
          namaSamaran: namaSamaran,
          jenjang: _jenjang,
          kelas: _kelas,
          statusYatim: _statusYatim,
          jumlahSaudara: jumlahSaudara,
          kondisiEkonomi: _kondisiEkonomi,
          statusPip: _statusPip,
          buruhTani: _buruhTani,
          namaWali: _namaWaliController.text.trim().isEmpty
              ? null
              : _namaWaliController.text.trim(),
          tanggalMasuk: tanggalStr,
          aktif: _aktif,
          keterangan: _keteranganController.text.trim().isEmpty
              ? null
              : _keteranganController.text.trim(),
        );
        await anakProvider.perbaruiAnak(updated);
      } else {
        final baru = Anak(
          kodeAnak: kode,
          namaLengkap: namaLengkap,
          namaSamaran: namaSamaran,
          jenjang: _jenjang,
          kelas: _kelas,
          statusYatim: _statusYatim,
          jumlahSaudara: jumlahSaudara,
          kondisiEkonomi: _kondisiEkonomi,
          statusPip: _statusPip,
          buruhTani: _buruhTani,
          namaWali: _namaWaliController.text.trim().isEmpty
              ? null
              : _namaWaliController.text.trim(),
          tanggalMasuk: tanggalStr,
          aktif: _aktif,
          keterangan: _keteranganController.text.trim().isEmpty
              ? null
              : _keteranganController.text.trim(),
        );
        await anakProvider.tambahAnak(baru);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Data anak berhasil diperbarui'
                  : 'Anak penerima beasiswa berhasil ditambahkan',
            ),
            backgroundColor: Colors.green[800],
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sedangMenyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pengaturan = context.watch<PengaturanProvider>();
    final saudara = int.tryParse(_jumlahSaudaraController.text) ?? 0;

    // Kalkulasi skor seleksi
    final skor = hitungSkor(
      kondisiEkonomi: _kondisiEkonomi,
      statusYatim: _statusYatim,
      jumlahSaudara: saudara,
      statusPip: _statusPip,
      bobotEkonomi: pengaturan.bobotEkonomi,
      bobotYatim: pengaturan.bobotYatim,
      bobotSaudara: pengaturan.bobotSaudara,
      bobotKip: pengaturan.bobotKip,
    );

    // Kalkulasi kebutuhan dana
    final kebutuhanBersih = hitungKebutuhanDana(
      jenjang: _jenjang,
      statusPip: _statusPip,
      biayaSd: pengaturan.biayaSd,
      biayaSmp: pengaturan.biayaSmp,
      biayaSma: pengaturan.biayaSma,
      pipSd: pengaturan.pipSd,
      pipSmp: pengaturan.pipSmp,
      pipSma: pengaturan.pipSma,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? 'Ubah Data Anak (${widget.anak!.kodeAnak})'
              : 'Tambah Anak Penerima (${_kodeAnak ?? "..."})',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Kartu Indikator Skor & Kebutuhan Realtime ────────────────
              Card(
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.green.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Skor Seleksi',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                          Text(
                            '$skor / 100',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                          const Text('Prioritas Kelayakan',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.black54)),
                        ],
                      ),
                      Container(
                          width: 1, height: 40, color: Colors.green.shade200),
                      Column(
                        children: [
                          const Text('Kebutuhan Dana / Thn',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                          Text(
                            formatRupiah(kebutuhanBersih),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                          Text(
                            _statusPip == StatusPip.sudahMenerima
                                ? 'Sudah dipotong PIP'
                                : 'Belum ada PIP',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Nama Lengkap (Rahasia Pengurus) ─────────────────────────
              TextFormField(
                controller: _namaLengkapController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap Anak * (Rahasia Pengurus)',
                  hintText: 'Contoh: Ahmad Fauzi Ramadan',
                  prefixIcon: Icon(Icons.person),
                  helperText:
                      'Hanya dilihat pengurus; tidak akan tercantum di laporan publik',
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => _updateNamaSamaranOtomatis(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama lengkap wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ─── Nama Samaran ────────────────────────────────────────────
              TextFormField(
                controller: _namaSamaranController,
                decoration: InputDecoration(
                  labelText: 'Nama Samaran / Publik *',
                  hintText: 'Contoh: A.F. - SD Kelas 3',
                  prefixIcon: const Icon(Icons.shield_outlined),
                  helperText: 'Ditampilkan pada daftar dan laporan publik',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.auto_fix_high),
                    tooltip: 'Buat otomatis dari nama & jenjang',
                    onPressed: _updateNamaSamaranOtomatis,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama samaran wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ─── Jenjang & Kelas ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<Jenjang>(
                      initialValue: _jenjang,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Jenjang *',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: Jenjang.values.map((j) {
                        return DropdownMenuItem(
                          value: j,
                          child: Text(j.label, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _jenjang = val;
                            final listKelas = _daftarKelasUntukJenjang(_jenjang);
                            if (!listKelas.contains(_kelas)) {
                              _kelas = listKelas.first;
                            }
                            _updateNamaSamaranOtomatis();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      key: ValueKey(_jenjang),
                      initialValue: _kelas,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Kelas *',
                      ),
                      items: _daftarKelasUntukJenjang(_jenjang).map((k) {
                        return DropdownMenuItem(
                          value: k,
                          child: Text('Kelas $k', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _kelas = val;
                            _updateNamaSamaranOtomatis();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Status Yatim / Piatu ─────────────────────────────────────
              DropdownButtonFormField<StatusYatim>(
                initialValue: _statusYatim,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Status Keluarga / Yatim *',
                  prefixIcon: Icon(Icons.favorite_border),
                ),
                items: StatusYatim.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s.label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _statusYatim = val);
                },
              ),
              const SizedBox(height: 16),

              // ─── Kondisi Ekonomi ─────────────────────────────────────────
              DropdownButtonFormField<KondisiEkonomi>(
                initialValue: _kondisiEkonomi,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Kondisi Ekonomi Keluarga *',
                  prefixIcon: Icon(Icons.home_work_outlined),
                ),
                items: KondisiEkonomi.values.map((k) {
                  return DropdownMenuItem(
                    value: k,
                    child: Text(k.label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _kondisiEkonomi = val);
                },
              ),
              const SizedBox(height: 16),

              // ─── Jumlah Saudara & Switch Buruh Tani ──────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _jumlahSaudaraController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Saudara *',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Wajib diisi';
                        }
                        if (int.tryParse(val) == null) {
                          return 'Angka tidak valid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: SwitchListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        title: const Text('Buruh Tani',
                            style: TextStyle(fontSize: 14)),
                        value: _buruhTani,
                        activeThumbColor: Colors.green[800],
                        onChanged: (val) => setState(() => _buruhTani = val),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Status KIP / PIP ─────────────────────────────────────────
              DropdownButtonFormField<StatusPip>(
                initialValue: _statusPip,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Status KIP / PIP Pemerintah *',
                  prefixIcon: Icon(Icons.card_membership_outlined),
                  helperText:
                      'Belum punya PIP mendapat skor seleksi lebih tinggi',
                ),
                items: StatusPip.values.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p.label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _statusPip = val);
                },
              ),
              const SizedBox(height: 16),

              // ─── Nama Wali Kelas / Orang Tua Penerima Uang Saku ──────────
              TextFormField(
                controller: _namaWaliController,
                decoration: const InputDecoration(
                  labelText: 'Penerima Uang Saku (Wali Kelas / Orang Tua)',
                  hintText: 'Contoh: Ibu Rina (Wali Kelas 3) / Ibu Maryam (Ibu)',
                  prefixIcon: Icon(Icons.contact_phone_outlined),
                  helperText:
                      'Uang saku disalurkan bulanan lewat wali kelas atau orang tua',
                ),
              ),
              const SizedBox(height: 16),

              // ─── Tanggal Masuk Program ───────────────────────────────────
              InkWell(
                onTap: _pilihTanggalMasuk,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Mulai Menerima Bantuan *',
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                  child: Text(
                    DateFormat('d MMMM yyyy', 'id_ID').format(_tanggalMasuk),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Status Aktif ────────────────────────────────────────────
              Card(
                margin: EdgeInsets.zero,
                child: SwitchListTile(
                  title: const Text('Status Aktif Menerima Beasiswa'),
                  subtitle: Text(
                    _aktif
                        ? 'Masih dalam tanggungan program'
                        : 'Selesai / Lulus / Pindah',
                  ),
                  value: _aktif,
                  activeThumbColor: Colors.green[800],
                  onChanged: (val) => setState(() => _aktif = val),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Catatan Tambahan ────────────────────────────────────────
              TextFormField(
                controller: _keteranganController,
                decoration: const InputDecoration(
                  labelText: 'Catatan / Alamat Rumah (Opsional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 28),

              // ─── Tombol Simpan ──────────────────────────────────────────
              FilledButton.icon(
                onPressed: _sedangMenyimpan ? null : _simpan,
                icon: _sedangMenyimpan
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _sedangMenyimpan
                      ? 'Menyimpan...'
                      : (_isEdit ? 'Simpan Perubahan' : 'Daftarkan Anak'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
