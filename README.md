# CBT ASAS SMK AS-SOLEHHIYAH

Starter aplikasi CBT ASAS berbasis HTML/CSS/JS + Supabase.

## Isi
- `index.html`: antarmuka login, dashboard admin/siswa, CRUD dasar siswa/mapel/soal/jadwal, pengerjaan ujian, deteksi tab/window focus, rekap/ranking dan CSV.
- `supabase/schema.sql`: tabel dan kebijakan RLS.
- `supabase/functions/admin-create-student/index.ts`: Edge Function untuk pembuatan akun siswa oleh admin.

## Setup Supabase
1. Buat project Supabase.
2. Buka SQL Editor dan jalankan `supabase/schema.sql`.
3. Buat akun administrator melalui Authentication > Users.
4. Ambil UUID admin tersebut. Jalankan SQL berikut dengan UUID yang benar:
   ```sql
   update public.profiles set role='admin', full_name='Administrator CBT' where id='UUID_ADMIN_AUTH';
   ```
5. Deploy Edge Function `admin-create-student` menggunakan Supabase CLI. Function memerlukan environment secrets bawaan Supabase `SUPABASE_URL`, `SUPABASE_ANON_KEY`, dan `SUPABASE_SERVICE_ROLE_KEY`. Jangan pernah memasukkan service-role key ke HTML atau GitHub.
6. Pastikan function dapat diakses dan validasi role admin berjalan.

## Publikasi GitHub + Vercel
1. Unggah `index.html` dan folder `supabase` ke repository GitHub.
2. Impor repository ke Vercel sebagai proyek static site; framework preset pilih **Other**, output directory root (`.`).
3. Setelah domain aktif, buka website. Isi Supabase Project URL dan anon/publishable key di layar konfigurasi.
4. Masuk menggunakan akun admin, lalu tambahkan siswa, mapel, soal, dan jadwal.

## Catatan sebelum digunakan untuk ujian resmi
Paket ini adalah starter/MVP. Untuk ujian resmi dengan integritas tinggi, wajib lakukan hardening backend sebelum digunakan: **jangan mengirim kunci jawaban ke browser siswa**; pindahkan kunci jawaban ke tabel khusus yang hanya dapat dibaca server/admin, dan lakukan penilaian melalui Edge Function. Tambahkan juga pembatasan akses soal berdasarkan jadwal/kelas, penguncian satu attempt, validasi durasi di server, backup, serta pengujian RLS. Client-side tab detection hanya bersifat pencatatan; browser tidak dapat mencegah semua cara siswa berpindah aplikasi atau memakai perangkat lain.

## Fitur starter
- Login email/password melalui Supabase Auth.
- Data siswa dengan email, NIS, kelas.
- Mata pelajaran dan KKTP.
- Bank soal pilihan ganda, gambar via URL, bobot.
- Jadwal ujian dan durasi.
- Auto timer, jawaban, pelanggaran tab/window, skor, status tuntas, ranking, ekspor CSV.
- Data tersimpan di Supabase dan dapat digunakan lintas tahun.
