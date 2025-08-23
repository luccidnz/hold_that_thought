#!/usr/bin/env bash
set -euo pipefail
THRESHOLD="${1:-80}" # default 80%
FILE="coverage/lcov.info"

if [ ! -f "$FILE" ]; then
  echo "coverage file not found: $FILE"
  exit 2
fi

PCT=$(awk '/^LF:/{split($0,a,":");lf=a[2]}/^LH:/{split($0,a,":");lh=a[2]}
/^end_of_record/{if(lf>0){T+=lf;H+=lh}lf=lh=0}
END{ if(T==0){print 0}else{printf "%.1f\n",(H*100)/T} }' "$FILE")

echo "Overall coverage: $PCT% (threshold: ${THRESHOLD}%)"
awk '
  /^SF:/ { gsub(/^SF:/,""); f=$0 }
  /^LF:/ { split($0,a,":"); lf=a[2] }
  /^LH:/ { split($0,a,":"); lh=a[2] }
  /^end_of_record/ {
    pct = (lf==0?0:(lh*100/lf));
    files[NR]=sprintf("%5.1f%% %s", pct, f);
    pctv[NR]=pct;
    count++;
    f=""; lf=0; lh=0;
  }
  END {
    n=(count<10?count:10);
    print "Lowest files:";
    # simple selection sort for bottom 10 to avoid sort dependency
    for(i=1;i<=count;i++){
      for(j=i+1;j<=count;j++){ if(pctv[i]>pctv[j]){ t=pctv[i]; pctv[i]=pctv[j]; pctv[j]=t; tf=files[i]; files[i]=files[j]; files[j]=tf } }
    }
    for(i=1;i<=n;i++) print "  " files[i];
  }
' "$FILE"

awk -v p="$PCT" -v t="$THRESHOLD" 'BEGIN{ exit (p+0>=t+0)?0:1 }'
