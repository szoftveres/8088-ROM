
#include "cutils.h"

#define SPT_144         (0x0012)
#define HPC_144         (0x2)

#define BPB_BASE        (0x0B)

#define LBA_INVALID     (0xFFFF)

#define SECT_SIZE       (512)
#define LAST_CLUSTER    (0xFFF)

#define FAT_TABLE_OFFSET    (bpb.resvd_sects)
#define ROOT_DIR_OFFSET     (FAT_TABLE_OFFSET + (bpb.no_of_fats * bpb.sects_per_fat) + bpb.hidden_sect_l)
#define CLUSTER_OFFSET      (ROOT_DIR_OFFSET + (bpb.max_root_entries * sizeof(dir_entry_t) / bpb.bytes_per_sect))

typedef struct __attribute__((__packed__)) bpb_144_s {
    unsigned int    bytes_per_sect;
    unsigned char   sect_per_cluster;
    unsigned int    resvd_sects;
    unsigned char   no_of_fats;
    unsigned int    max_root_entries;
    unsigned int    total_sects;
    unsigned char   media_descr;
    unsigned int    sects_per_fat;

    unsigned int    sects_per_cyl;
    unsigned int    heads;
    unsigned int    hidden_sect_l;
    unsigned int    hidden_sect_h;
    unsigned int    total_sect_l;
    unsigned int    total_sect_h;

    unsigned char   drive_no;
    unsigned char   reserved;
    unsigned char   ext_boot_signature;
    unsigned int    vol_serial_id_l;
    unsigned int    vol_serial_id_h;

    char            volume_label[11];
    char            fs_type[8];
} bpb_144_t;


typedef struct __attribute__((__packed__)) dir_entry_s {
    char            name[8];
    char            ext[3];
    unsigned char   attribs;
    unsigned int    reserved;
    unsigned int    creat_time;
    unsigned int    creat_date;
    unsigned int    access_date;
    unsigned int    ignore;
    unsigned int    mod_time;
    unsigned int    mod_date;
    unsigned int    first_cluster;
    unsigned int    size_l;
    unsigned int    size_h;
} dir_entry_t;


char dir_buf[512];


int disk_read_lba_144 (int lba, void* buf) {
    int c = lba / (HPC_144 * SPT_144);
    int h = (lba / SPT_144) % HPC_144;
    int s = (lba % SPT_144) + 1;

    return bios_disk_read_chs(c, h, s, buf);
}


char namebuf[9];
char extbuf[4];
bpb_144_t   bpb;


unsigned int
get_next_cluster (unsigned int cluster) {
    int odd;
    unsigned int b;
    int disk_rc;
    unsigned int lba;

    lba = FAT_TABLE_OFFSET + (cluster * 3 / (SECT_SIZE * 2));      /* sector to load */
    b = cluster * 3;
    odd = b % 2;            /* This entry is shifted */
    b = b / 2;              /* Mul by 1.5 */
    b %= SECT_SIZE;


    disk_read_lba_144(lba, dir_buf);

    cluster = *((unsigned int*)&dir_buf[b]);

    if (b == SECT_SIZE - 1) {   /* Need to load the next sector too */
        disk_read_lba_144(lba + 1 , dir_buf);
        /* The -1 thing is addressing the 1st byte of the buffer as if it was the upper byte */
        cluster = (cluster & 0x00FF) | ((*((unsigned int*)&dir_buf[-1])) & 0xFF00);
    }

    if (odd) {
        cluster /= 16;
    }
    cluster &= 0x0FFF;

    return cluster;
}




dir_entry_t*
get_direntry (int n) {
    char *buf;
    int disk_rc;
    unsigned int lba = ROOT_DIR_OFFSET + (n / (SECT_SIZE / sizeof(dir_entry_t)));
    disk_read_lba_144(lba, dir_buf);
    return (dir_entry_t*)&dir_buf[(n % (SECT_SIZE / sizeof(dir_entry_t))) * sizeof(dir_entry_t)];
}

void
dump_file (int cluster, int lines) {
    int disk_rc;
    char* buf;
    unsigned int lba = CLUSTER_OFFSET + cluster - 2; /* The first two clusters are reserved */
    disk_read_lba_144(lba, dir_buf);

    buf_dump(dir_buf, lines);
}



void dump_rootdir (void) {
    int i;
    dir_entry_t* direntry;
    int cluster;
    int blocks;

    bios_printf(csegstr("\n"));

    bios_disk_reset();
    disk_read_lba_144(0, dir_buf);
    memcpy(&bpb, (dir_buf + BPB_BASE), sizeof(bpb_144_t));

    for (i = 0; i != bpb.max_root_entries; i++) {
        direntry = get_direntry(i);
        switch (*((char*)direntry)) {
          case 0x00:
          case 0x05:
          case 0xE5:
            break;
          default:
            memcpy(namebuf, direntry->name, 8);
            namebuf[8] = '\0';
            memcpy(extbuf, direntry->ext, 3);
            extbuf[3] = '\0';
            bios_printf(csegstr("[%s.%s] start:%4x size:%4x%4x\n"),
                    namebuf, extbuf,
                    direntry->first_cluster,
                    direntry->size_h,
                    direntry->size_l);

            cluster = direntry->first_cluster;
            dump_file(cluster, 32);
            blocks = 0;
            while (cluster != LAST_CLUSTER) {
                blocks++;
//                bios_printf(csegstr("%3x "), cluster);
                cluster = get_next_cluster(cluster);
            }
            bios_printf(csegstr("%i blocks\n"), blocks);
            break;
        }
    }
}

/*
 * getting the position is easy: b % SECT_SIZE
 */
int
seek_cluster (int cluster, int b) {
    while (b / SECT_SIZE) {
        cluster = get_next_cluster(cluster);
        b -= SECT_SIZE;
    }
    return cluster;
}



