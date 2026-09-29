// Static script only; all private text is inserted with textContent in the local judge page.
export const REFERENCE_FORM_UI = `
function referenceForm(){
  const root=el('extra');
  const section=(title)=>{const f=document.createElement('fieldset'),l=document.createElement('legend');put(l,title);f.append(l);root.append(f);return f};
  const markDirty=()=>put(el('status'),'변경됨 · 라벨 저장 또는 다음을 눌러주세요');
  const radios=(title,key,values)=>{const f=section(title);for(const [value,label]of values){const b=document.createElement('button');put(b,label);b.dataset.referenceKey=key;b.dataset.value=value;b.setAttribute('aria-pressed',referenceLabels[key]===value);b.onclick=()=>{referenceLabels[key]=value;f.querySelectorAll('button').forEach(x=>x.setAttribute('aria-pressed',x===b));markDirty()};f.append(b)}};
  radios('첫 문장 유형','opening_type',[['dialogue','대사'],['action','행동'],['situation','상황 제시'],['sense','감각'],['monologue','속말·독백'],['explanation','설명']]);
  const opening=section('도입 · 첫 사건이 시작되는 문단을 선택하세요');
  state.paragraphs.slice(0,state.reference_form.opening_paragraphs).forEach((text,index)=>{const p=document.createElement('p'),b=document.createElement('button');put(p,text);put(b,'첫 사건: 문단 '+(index+1));b.dataset.eventPara=index+1;b.setAttribute('aria-pressed',referenceLabels.first_event_para===index+1);b.onclick=()=>{referenceLabels.first_event_para=index+1;opening.querySelectorAll('button').forEach(x=>x.setAttribute('aria-pressed',x===b));markDirty()};opening.append(b,p)});
  const reveal=section('2,000자 안에 드러난 것 · 해당하는 항목 모두');
  for(const [key,label]of [['circumstance','주인공의 처지'],['goal_problem','당장의 목표·문제'],['anomaly','이 이야기의 이상함']]){const l=document.createElement('label'),c=document.createElement('input');c.type='checkbox';c.checked=referenceLabels.reveal_by_2000.includes(key);c.dataset.reveal=key;c.onchange=()=>{referenceLabels.reveal_by_2000=Array.from(reveal.querySelectorAll('input:checked')).map(x=>x.dataset.reveal);markDirty()};l.append(c,document.createTextNode(label));reveal.append(l)}
  const ending=section('1화 끝');state.paragraphs.slice(state.reference_form.opening_paragraphs).forEach(text=>{const p=document.createElement('p');put(p,text);ending.append(p)});
  radios('끝맺음 유형','ending_type',[['new_presence','새 인물·존재 등장'],['new_information','새 정보·반전'],['before_crisis','위기 직전'],['before_choice','선택 직전'],['dialogue','대사 한 줄'],['image','여운 이미지']]);
  const memo=section('왜 다음 화를 눌렀나요? · 선택 사항 · 원문 인용 없이 자신의 말로');const note=document.createElement('textarea');note.maxLength=240;note.setAttribute('aria-label','다음 화를 누른 이유');note.value=referenceLabels.hook_note;note.oninput=()=>{referenceLabels.hook_note=note.value;markDirty()};memo.append(note);
}
`;
