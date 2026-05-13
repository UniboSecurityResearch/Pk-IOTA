import React from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

const CategoryTimeline = () => {
  const data = [
    { year: 2009, "Job Role": 1 },
    { year: 2010, "Age": 1, "Gender": 1 },
    { year: 2011, "Culture": 1, "Gender": 1, "Sector": 1 },
    { year: 2014, },
    { year: 2015, "Age": 1, "Cybersecurity Background": 1 },
    { year: 2016, "Age": 2, "Gender": 2, "Education Level": 1, "Social Influence": 1, "Culture": 1 },
    { year: 2017, "Age": 2, "Gender": 3, "Culture": 3, "Sector": 2 },
    { year: 2018, "Age": 2, "Gender": 1, "Education Level": 1, "Sector": 2 },
    { year: 2019, "Age": 2, "Gender": 2, "Education Level": 1, "Sector": 1, "Work Experience": 1, "Culture": 1 },
    { year: 2020, "Age": 4, "Gender": 3, "Education Level": 1, "Culture": 1, "Sector": 1, "Job Role": 1 },
    { year: 2021, "Gender": 2, "Education Level": 1, "Sector": 1, "Job Experience": 1 },
    { year: 2022, "Age": 2, "Gender": 3, "Education Level": 2, "Culture": 1 },
    { year: 2023, "Age": 4, "Gender": 2, "Education Level": 4, "Sector": 3, "Culture": 3 },
    { year: 2024, "Age": 3, "Gender": 3, "Education Level": 2, "Culture": 4, "Job Role": 1, "Job Experience": 1 }
  ];

  return (
    <div className="w-full h-96 p-4">
      <h2 className="text-xl font-bold text-center mb-4">Evolution of Demographic Categories in Cybersecurity Research (2009-2024)</h2>
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis 
            dataKey="year"
            label={{ value: 'Year', position: 'bottom', offset: 0 }}
          />
          <YAxis 
            label={{ value: 'Number of Studies', angle: -90, position: 'insideLeft' }}
          />
          <Tooltip />
          <Legend />
          <Line type="monotone" dataKey="Age" stroke="#0000FF" strokeWidth={2} />
          <Line type="monotone" dataKey="Gender" stroke="#FF0000" strokeWidth={2} />
          <Line type="monotone" dataKey="Education Level" stroke="#00FF00" strokeWidth={2} />
          <Line type="monotone" dataKey="Culture" stroke="#800080" strokeWidth={2} />
          <Line type="monotone" dataKey="Sector" stroke="#FFA500" strokeWidth={2} />
          <Line type="monotone" dataKey="Job Role" stroke="#A52A2A" strokeWidth={2} />
          <Line type="monotone" dataKey="Job Experience" stroke="#FF1493" strokeWidth={2} />
          <Line type="monotone" dataKey="Work Experience" stroke="#808080" strokeWidth={2} />
          <Line type="monotone" dataKey="Cybersecurity Background" stroke="#006400" strokeWidth={2} />
          <Line type="monotone" dataKey="Social Influence" stroke="#00FFFF" strokeWidth={2} />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};

export default CategoryTimeline;