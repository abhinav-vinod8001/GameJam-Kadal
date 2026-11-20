"""Rebuild KADAL's small original sound library. Python standard library only."""
import math
import random
import struct
import wave
from pathlib import Path

random.seed(1870)
OUT = Path(__file__).resolve().parents[1] / "assets/audio"
RATE = 22050

def write(name, samples):
    peak = max(1, max(abs(x) for x in samples))
    pcm = b"".join(struct.pack("<h", int(max(-1, min(1, x / peak)) * 27000)) for x in samples)
    with wave.open(str(OUT / (name + ".wav")), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(pcm)

def sound(name, duration, kind, frequency=300):
    samples = []
    smooth = 0
    for i in range(int(RATE * duration)):
        t = i / RATE
        u = t / duration
        noise = random.uniform(-1, 1)
        alpha = min(.75, frequency / 1800)
        smooth = smooth * (1-alpha) + noise * alpha
        if kind == "swish":
            air = smooth if name == "staff" else noise-smooth*.7
            tone = math.sin(math.tau*(frequency*t + frequency*t*t*.5))*.035
            value = (air*.65+tone) * math.sin(math.pi*u)**2
        elif kind == "impact":
            value = (smooth*.7+math.sin(math.tau*frequency*t*math.exp(-t*6))*.3)*math.exp(-u*8)
        elif kind == "metal":
            value = sum(math.sin(math.tau*frequency*m*t)*math.exp(-t*(4+m))/(j+2) for j,m in enumerate([1,1.47,2.13,2.91]))
        elif kind == "chime":
            value = sum(math.sin(math.tau*frequency*m*max(0,t-j*.07))*math.exp(-max(0,t-j*.07)*6)*(t>j*.07)/3 for j,m in enumerate([1,1.25,1.5]))*min(1,t*100)
        else:
            value = smooth*math.sin(math.pi*u)**.5*.7+math.sin(t*80)*smooth*.3
        samples.append(value)
    write(name, samples)

for name, duration, freq in [("sword",.3,500),("spear",.22,650),("staff",.37,140),("dagger",.15,900),("urumi",.65,350),("dodge",.32,300)]:
    sound(name,duration,"swish",freq)
for name, duration, freq in [("impact",.23,110),("step",.12,120),("splash",.3,160),("telegraph",.22,180),("death",.75,65)]:
    sound(name,duration,"impact",freq)
for name, duration, freq in [("block",.4,710),("parry",.85,970),("equip",.18,750)]:
    sound(name,duration,"metal",freq)
for name, freq in [("discover",440),("purchase",660),("heal",520)]:
    sound(name,.9,"chime",freq)
sound("thunder",3.2,"thunder")
for name in ["coast","rain"]:
    duration=12
    samples=[]
    smooth=0
    for i in range(RATE*duration):
        t=i/RATE
        smooth=.95*smooth+.05*random.uniform(-1,1)
        value=smooth*(.45+.15*math.sin(math.tau*t/duration))
        if name=="coast":
            for start in [1.2,1.6,4.3,7.7,8.1,10.5]:
                u=t-start
                if 0<u<.22:
                    value+=math.sin(math.tau*(2100*u+900*u*u))*math.sin(math.pi*u/.22)*.055
            value+=math.sin(math.tau*73*t)*.008
        else:
            value+=random.uniform(-1,1)*.055
        samples.append(value)
    fade=RATE//3
    for i in range(fade):
        samples[-fade+i]=samples[-fade+i]*(1-i/fade)+samples[i]*(i/fade)
    write(name,samples)
print("Built 20 original WAV assets.")
